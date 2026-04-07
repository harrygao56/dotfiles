-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here-- Show gitignored + hidden files in the "Find Files (Root Dir)" picker

local pick = require("lazyvim.util").pick

-- Root dir
vim.keymap.set("n", "<space>ff", function()
  pick("files", {
    root = true,
    hidden = true,
    ignored = true, -- show gitignored
  })()
end, { desc = "Find Files (Root Dir, incl ignored)" })

-- CWD
vim.keymap.set("n", "<space><space>", function()
  pick("files", {
    hidden = true,
    ignored = true, -- show gitignored
  })()
end, { desc = "Find Files (CWD, incl ignored)" })
