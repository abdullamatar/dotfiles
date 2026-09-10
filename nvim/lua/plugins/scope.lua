-- Per-tab-page buffer lists (VS Code editor-group model).
-- scope.nvim toggles 'buflisted' on TabEnter/TabLeave, so bufferline, :ls and
-- the buffer picker only show the current tab's buffers.
return {
  {
    "tiagovla/scope.nvim",
    event = "VeryLazy",
    opts = {},
    config = function(_, opts)
      require("scope").setup(opts)
      -- Keep per-tab state across persistence.nvim sessions (<leader>qs / <leader>ql).
      local group = vim.api.nvim_create_augroup("scope_persistence", { clear = true })
      vim.api.nvim_create_autocmd("User", { group = group, pattern = "PersistenceSavePre", command = "ScopeSaveState" })
      vim.api.nvim_create_autocmd("User", { group = group, pattern = "PersistenceLoadPost", command = "ScopeLoadState" })
    end,
  },
  -- LazyVim hides the bufferline when a tab lists a single buffer, which with
  -- scope.nvim is every fresh tab. Always show it so the tab indicators stay visible.
  { "akinsho/bufferline.nvim", opts = { options = { always_show_bufferline = true } } },
}
