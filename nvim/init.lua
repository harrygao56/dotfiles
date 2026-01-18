-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
vim.lsp.enable("tsgo")
vim.opt.autoread = true

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  pattern = "*",
  command = "checktime",
})
