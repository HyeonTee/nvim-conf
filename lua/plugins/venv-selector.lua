return {
  -- Python 가상환경 선택기. 선택한 venv 를 basedpyright 에 반영하고,
  -- 작업 디렉토리별로 기억해서 다음 실행 시 자동으로 다시 활성화한다.
  -- venv 검색에 fd 바이너리 필요 (brew install fd).
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim",
    },
    ft = "python",
    cmd = "VenvSelect",
    keys = {
      { "<leader>v", "<cmd>VenvSelect<cr>", desc = "Python venv 선택" },
    },
    opts = {},
  },
}
