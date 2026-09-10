-- LSPs for track-sim-stack. Two python worlds live in this repo:
--   * aircraft/aircraft_ws/**  ROS 2 Humble code, python 3.10 + rclpy, which
--     only exist inside the `aircraft-lsp` docker container. clangd and
--     basedpyright are exec'd in there via the wrappers in ~/.local/bin.
--   * everything else          host scripts against the uv venv in .venv
--     (python 3.13, pymavlink, opencv). Served by the mason basedpyright on
--     the host, using whatever venv was active in the shell that launched nvim.
-- Only active when nvim is started inside the repo; every other project
-- keeps the stock mason-installed servers.
local repo = vim.fn.expand("~/7amdla/track-sim-stack")
if not vim.startswith(vim.fn.getcwd(), repo) then
  return {}
end

local ros_ws = repo .. "/aircraft/aircraft_ws"

local function in_ros_ws(bufnr)
  return vim.startswith(vim.api.nvim_buf_get_name(bufnr), ros_ws .. "/")
end

-- Node-based servers (basedpyright) poll the client PID sent in `initialize`
-- every 3 s and exit(1) when it is gone. Inside the container the host nvim
-- PID does not exist, so the server killed itself 3 s after attaching.
-- processId = null (allowed by the LSP spec) disables that watcher.
local function drop_process_id(params)
  params.processId = vim.NIL
end

-- Goto-definition from clangd can land on files that only exist inside the
-- container: px4_msgs (/aas/github_ws), generated msg headers under
-- /aas/aircraft_ws/install, and the container's libstdc++ / gcc headers
-- (gcc 11 there, 15 on the host). For those, fill the buffer read-only from
-- the container instead of opening an empty buffer at a path the host lacks.
-- Paths that do exist on the host (the /opt/ros/humble header copy, most of
-- /usr/include) are read normally.
vim.api.nvim_create_autocmd("BufReadCmd", {
  group = vim.api.nvim_create_augroup("track_sim_container_files", { clear = true }),
  pattern = { "/aas/*", "/opt/ros/*", "/usr/include/*", "/usr/lib/gcc/*", "/usr/local/lib/*" },
  callback = function(ev)
    local path = vim.api.nvim_buf_get_name(ev.buf)
    local st = vim.uv.fs_stat(path)
    if st and st.type == "directory" then
      return
    end
    if st then
      vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, vim.fn.readfile(path))
      vim.bo[ev.buf].modified = false
      vim.api.nvim_exec_autocmds("BufReadPost", { buffer = ev.buf })
      return
    end
    local r = vim.system({ "docker", "exec", "aircraft-lsp", "cat", path }, { text = true }):wait()
    if r.code ~= 0 then
      vim.notify("aircraft-lsp: cannot read " .. path .. "\n" .. (r.stderr or ""), vim.log.levels.WARN)
      return
    end
    local lines = vim.split(r.stdout, "\n", { plain = true })
    if lines[#lines] == "" then
      table.remove(lines)
    end
    vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, lines)
    local bo = vim.bo[ev.buf]
    bo.modified = false
    bo.buftype = "nowrite"
    bo.readonly = true
    bo.modifiable = false
    bo.swapfile = false
    -- extensionless libstdc++ headers (/usr/include/c++/11/vector) have no match
    bo.filetype = vim.filetype.match({ buf = ev.buf, filename = path }) or (path:find("/c%+%+/") and "cpp") or ""
  end,
})

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          cmd = { vim.fn.expand("~/.local/bin/clangd-aircraft") },
          mason = false,
          -- Only attach to files in the repo. Headers pulled from the container
          -- (see BufReadCmd above) are read-only reference views; letting clangd
          -- attach to them would spawn a second rootless clangd per header.
          root_dir = function(bufnr, on_dir)
            if vim.startswith(vim.api.nvim_buf_get_name(bufnr), repo .. "/") then
              on_dir(repo)
            end
          end,
        },
        -- pyright (LazyVim python extra default) is replaced by basedpyright.
        pyright = { enabled = false },

        -- ROS python: basedpyright inside the container. Root is the colcon
        -- workspace so the repo-root pyproject.toml/.venv never leak in.
        basedpyright_aircraft = {
          cmd = { vim.fn.expand("~/.local/bin/basedpyright-aircraft") },
          filetypes = { "python" },
          mason = false,
          before_init = drop_process_id,
          root_dir = function(bufnr, on_dir)
            if in_ros_ws(bufnr) then
              on_dir(ros_ws)
            end
          end,
          settings = {
            basedpyright = {
              analysis = {
                -- container paths: mirrors .devcontainer/aircraft/devcontainer.json
                extraPaths = {
                  "/opt/ros/humble/lib/python3.10/site-packages",
                  "/opt/ros/humble/local/lib/python3.10/dist-packages",
                  "/aas/aircraft_ws/install/autopilot_interface_msgs/local/lib/python3.10/dist-packages",
                  "/aas/aircraft_ws/install/autopilot_interface_msgs/lib/python3.10/site-packages",
                },
              },
            },
          },
        },

        -- Host python: mason basedpyright, everything outside the ROS ws.
        -- pythonPath follows the venv that was active when nvim started.
        basedpyright = {
          root_dir = function(bufnr, on_dir)
            if not in_ros_ws(bufnr) then
              on_dir(repo)
            end
          end,
          settings = {
            python = {
              pythonPath = vim.env.VIRTUAL_ENV and (vim.env.VIRTUAL_ENV .. "/bin/python") or nil,
            },
          },
        },
      },
    },
  },

  -- venv-selector (pulled in by the LazyVim python extra) force-restarts every
  -- python LSP client with the picked interpreter, which is a dangling path
  -- inside the container. The venv comes from the launching shell instead.
  { "linux-cultist/venv-selector.nvim", enabled = false },
}
