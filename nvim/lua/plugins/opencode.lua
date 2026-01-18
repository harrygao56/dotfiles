return {
  "NickvanDyke/opencode.nvim",
  dependencies = {
    -- Recommended for `ask()` and `select()`.
    -- Required for `snacks` provider.
    ---@module 'snacks' <- Loads `snacks.nvim` types for configuration intellisense.
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      -- Your configuration, if any — see `lua/opencode/config.lua`, or "goto definition".
    }

    -- Required for `opts.events.reload`.
    vim.o.autoread = true

    -- Toggle opencode panel
    vim.keymap.set({ "n", "t" }, "<leader>ox", function()
      require("opencode").select()
    end, { desc = "opencode: open select menu" })

    -- Ask opencode (no automatic context)
    vim.keymap.set({ "n", "x" }, "<leader>oa", function()
      require("opencode").ask("", { submit = true })
    end, { desc = "opencode: ask (blank)" })

    -- Select opencode action
    vim.keymap.set({ "n", "x" }, "<leader>ot", function()
      require("opencode").ask("@this ", { submit = true })
    end, { desc = "opencode: ask with @this" })
  end,
}
