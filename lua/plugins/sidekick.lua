require('sidekick').setup({
  -- add any options here
  cli = {
    mux = {
      backend = "tmux",
      enabled = true,
    },
    tools = {
      claude = { cmd = { "claude" } },
      copilot = { cmd = { "copilot", "--banner" } },
      cursor = { cmd = { "cursor-agent" } },
      opencode = {
        cmd = { "opencode" },
        -- HACK: https://github.com/sst/opencode/issues/445
        env = { OPENCODE_THEME = "system" },
      },
    },
  },
})

-- Register keybindings
-- Note: These keybindings should ideally be registered via Packer's keys parameter in plugins.lua
-- For now, they are registered here after sidekick is initialized

local sidekick = require("sidekick")
local sidekick_cli = require("sidekick.cli")

local keymaps = {
  {
    mode = { "i", "n" },
    lhs = "<tab>",
    rhs = function()
      if not sidekick.nes_jump_or_apply() then
        return "<Tab>"
      end
    end,
    opts = { noremap = true, expr = true, desc = "Goto/Apply Next Edit Suggestion" },
  },
  {
    mode = { "n", "t", "i", "x" },
    lhs = "<c-.>",
    rhs = function() sidekick_cli.toggle() end,
    opts = { noremap = true, desc = "Sidekick Toggle" },
  },
  {
    mode = "n",
    lhs = "<leader>aa",
    rhs = function() sidekick_cli.toggle() end,
    opts = { noremap = true, desc = "Sidekick Toggle CLI" },
  },
  {
    mode = "n",
    lhs = "<leader>as",
    rhs = function() sidekick_cli.select() end,
    opts = { noremap = true, desc = "Select CLI" },
  },
  {
    mode = "n",
    lhs = "<leader>ad",
    rhs = function() sidekick_cli.close() end,
    opts = { noremap = true, desc = "Detach a CLI Session" },
  },
  {
    mode = { "x", "n" },
    lhs = "<leader>at",
    rhs = function() sidekick_cli.send({ msg = "{this}" }) end,
    opts = { noremap = true, desc = "Send This" },
  },
  {
    mode = "n",
    lhs = "<leader>af",
    rhs = function() sidekick_cli.send({ msg = "{file}" }) end,
    opts = { noremap = true, desc = "Send File" },
  },
  {
    mode = "x",
    lhs = "<leader>av",
    rhs = function() sidekick_cli.send({ msg = "{selection}" }) end,
    opts = { noremap = true, desc = "Send Visual Selection" },
  },
  {
    mode = { "n", "x" },
    lhs = "<leader>ap",
    rhs = function() sidekick_cli.prompt() end,
    opts = { noremap = true, desc = "Sidekick Select Prompt" },
  },
  {
    mode = "n",
    lhs = "<leader>ac",
    rhs = function() sidekick_cli.toggle({ name = "opencode", focus = true }) end,
    opts = { noremap = true, desc = "Sidekick Toggle OpenCode" },
  },
}

for _, keymap in ipairs(keymaps) do
  vim.keymap.set(keymap.mode, keymap.lhs, keymap.rhs, keymap.opts)
end
