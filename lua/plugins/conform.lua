return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        go = { "goimports", "gofmt" },
        rust = { "rustfmt" },
        python = { "ruff_format" },
      },
      -- 저장 시 자동 포맷. conform에 정의된 포맷터가 없으면 LSP 포맷으로 폴백.
      format_on_save = {
        lsp_format = "fallback",
        timeout_ms = 1000,
      },
    },
  },
}
