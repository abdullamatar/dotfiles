-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

map("i", "jk", "<Esc>", { desc = "Escape insert mode" })

-- <leader>w = save. LazyVim uses <leader>w as a window prefix; drop its two
-- submaps so the save fires instantly (windows stay on <C-w>, zoom on <leader>uZ)
vim.keymap.del("n", "<leader>wd")
vim.keymap.del("n", "<leader>wm")
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save File" })

-- <leader>l = LSP group (AstroNvim layout). LazyVim binds <leader>l to :Lazy,
-- which would make the prefix ambiguous; :Lazy moves to <leader>lz.
-- The capability-gated half of the group lives in lua/plugins/lsp-keys.lua.
vim.keymap.del("n", "<leader>l")
map("n", "<leader>lz", "<cmd>Lazy<cr>", { desc = "Lazy (plugin manager)" })
map({ "n", "x" }, "<leader>lf", function() LazyVim.format({ force = true }) end, { desc = "Format Buffer" })
map("n", "<leader>ld", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "<leader>lD", function() Snacks.picker.diagnostics() end, { desc = "Search Diagnostics" })
map("n", "<leader>li", function() Snacks.picker.lsp_config() end, { desc = "LSP Info" })
map("n", "<leader>lS", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols Outline" })

-- EasyMotion-style jumps on flash.nvim (already shipped by LazyVim).
--   <leader><leader>w / b : label every word start after / before the cursor
--   <leader><leader>j / k : label every line below / above the cursor
-- max_length = 0 makes the next keypress a label choice, not a pattern char.
-- LazyVim's <leader><space> (find files) would make the prefix ambiguous, so
-- it is dropped; <leader>ff is the same picker.
pcall(vim.keymap.del, "n", "<leader><space>")
local function flash_to(pattern, forward)
  return function()
    require("flash").jump({
      pattern = pattern,
      search = { mode = "search", max_length = 0, forward = forward, wrap = false, multi_window = false },
      label = { after = { 0, 0 } },
    })
  end
end
map({ "n", "x", "o" }, "<leader><leader>w", flash_to([[\<]], true), { desc = "Jump to word (forward)" })
map({ "n", "x", "o" }, "<leader><leader>b", flash_to([[\<]], false), { desc = "Jump to word (backward)" })
map({ "n", "x", "o" }, "<leader><leader>j", flash_to("^", true), { desc = "Jump to line (down)" })
map({ "n", "x", "o" }, "<leader><leader>k", flash_to("^", false), { desc = "Jump to line (up)" })

-- <leader>lw: basedpyright typeCheckingMode "recommended" <-> "standard".
-- basedpyright's default "recommended" adds the reportUnknown* / reportAny /
-- reportMissingParameterType family as warnings on top of pyright's
-- "standard" (390 of the 399 diagnostics in yolo_node.py). Flipping the mode
-- on the live server removes them everywhere (signs, floats, Trouble, ]d)
-- instead of only hiding them. A typeCheckingMode set in pyproject.toml
-- overrides this setting for that root.
local basedpyright_mode = "recommended"
local function set_basedpyright_mode(mode, clients)
  basedpyright_mode = mode
  for _, client in ipairs(clients or vim.lsp.get_clients()) do
    if client.name:match("^basedpyright") then
      client.settings = vim.tbl_deep_extend("force", client.settings or {}, { basedpyright = { analysis = { typeCheckingMode = mode } } })
      client:notify("workspace/didChangeConfiguration", { settings = client.settings })
    end
  end
end
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("basedpyright_mode", { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and basedpyright_mode ~= "recommended" then
      set_basedpyright_mode(basedpyright_mode, { client })
    end
  end,
})
Snacks.toggle({
  name = "basedpyright Warnings (recommended mode)",
  get = function() return basedpyright_mode == "recommended" end,
  set = function(on) set_basedpyright_mode(on and "recommended" or "standard") end,
}):map("<leader>lw")
