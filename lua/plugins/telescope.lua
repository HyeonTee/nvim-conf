return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    keys = {
      {
        ";f",
        function()
          require("telescope.builtin").find_files({ hidden = true })
        end,
        desc = "파일 검색",
      },
      {
        ";r",
        function()
          require("telescope.builtin").live_grep()
        end,
        desc = "Live grep",
      },
      {
        ";b",
        function()
          require("telescope.builtin").buffers()
        end,
        desc = "버퍼 목록",
      },
      {
        ";o",
        function()
          require("telescope.builtin").oldfiles()
        end,
        desc = "최근 파일",
      },
      {
        ";t",
        function()
          require("telescope.builtin").help_tags()
        end,
        desc = "도움말 검색",
      },
      {
        ";;",
        function()
          require("telescope.builtin").resume()
        end,
        desc = "이전 picker 재개",
      },
      {
        ";e",
        function()
          require("telescope.builtin").diagnostics()
        end,
        desc = "진단 목록",
      },
      {
        ";s",
        function()
          require("telescope.builtin").lsp_document_symbols()
        end,
        desc = "문서 심볼",
      },
    },
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        path_display = { "truncate" },
      },
    },
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf")
    end,
  },
}
