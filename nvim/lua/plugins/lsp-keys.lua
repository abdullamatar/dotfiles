-- AstroNvim-style <leader>l LSP group, on top of LazyVim's <leader>c / g* maps.
-- These are buffer-local and only appear when an attached client supports the
-- method (LazyVim's `has` gate). The maps that work without an LSP client
-- (format, diagnostics list, outline, info) are global, in config/keymaps.lua.
return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers["*"] = opts.servers["*"] or {}
      opts.servers["*"].keys = opts.servers["*"].keys or {}
      -- stylua: ignore
      vim.list_extend(opts.servers["*"].keys, {
        { "<leader>la", vim.lsp.buf.code_action, desc = "Code Action", mode = { "n", "x" }, has = "codeAction" },
        { "<leader>lA", function() LazyVim.lsp.action.source() end, desc = "Source Action", has = "codeAction" },
        { "<leader>lr", vim.lsp.buf.rename, desc = "Rename Symbol", has = "rename" },
        { "<leader>lR", function() Snacks.picker.lsp_references() end, desc = "References", has = "references" },
        { "<leader>lh", vim.lsp.buf.signature_help, desc = "Signature Help", has = "signatureHelp" },
        { "<leader>ls", function() Snacks.picker.lsp_symbols({ filter = LazyVim.config.kind_filter }) end, desc = "Document Symbols", has = "documentSymbol" },
        { "<leader>lG", function() Snacks.picker.lsp_workspace_symbols({ filter = LazyVim.config.kind_filter }) end, desc = "Workspace Symbols", has = "workspace/symbol" },
        { "<leader>ll", vim.lsp.codelens.run, desc = "Run Codelens", mode = { "n", "x" }, has = "codeLens" },
        { "<leader>lL", vim.lsp.codelens.refresh, desc = "Refresh Codelens", has = "codeLens" },
        { "gl", vim.diagnostic.open_float, desc = "Hover Diagnostics" },
      })
    end,
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>l", group = "lsp" },
      },
    },
  },
}
