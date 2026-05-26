return {
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
    config = function(_, opts)
      require("nvim-surround").setup(opts)
      vim.keymap.set("x", "(", "c()<Esc>P", { desc = "Surround with ()" })
      vim.keymap.set("x", "[", "c[]<Esc>P", { desc = "Surround with []" })
      vim.keymap.set("x", "{", "c{}<Esc>P", { desc = "Surround with {}" })
    end,
  },
}
