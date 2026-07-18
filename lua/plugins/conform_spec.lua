require("packer").use({
  "stevearc/conform.nvim",
  config = function()
    require("plugins.conform").setup()
  end,
})
