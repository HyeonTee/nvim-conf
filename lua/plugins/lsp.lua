return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "stylua", -- Lua 포매터
        "selene", -- Lua 린터
        "luacheck", -- Lua 린터
        "shellcheck", -- 쉘 스크립트 린터
        "shfmt", -- 쉘 스크립트 포매터
        "tailwindcss-language-server", -- Tailwind CSS 언어 서버
        "typescript-language-server", -- TypeScript 언어 서버
        "css-lsp", -- CSS 언어 서버
        "rust-analyzer", -- Rust 언어 서버
        "gopls", -- Go 언어 서버
        "golangci-lint", -- Go 린터
        "goimports", -- Go 코드 포매터
        "delve", -- Go 디버거
      })
    end,
  },
}
