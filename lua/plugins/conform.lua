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
        -- import 정리(isort 역할) 후 포맷. 둘 다 mason 의 ruff 바이너리 하나로 동작.
        python = { "ruff_organize_imports", "ruff_format" },
        -- java: 명시적 포매터를 두지 않음. conform 의 lsp_format = "fallback" 이
        -- 동작해서 jdtls 의 자체 포맷 (Eclipse 표준, 4칸 들여쓰기) 으로 처리됨.
      },
      -- 저장 시 자동 포맷. conform에 정의된 포맷터가 없으면 LSP 포맷으로 폴백.
      format_on_save = {
        lsp_format = "fallback",
        timeout_ms = 1000,
      },
    },
  },
}
