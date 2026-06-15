return {
  -- LSP/포매터/린터 바이너리 설치 관리자
  -- nvim-java 가 jdtls/lombok/java-test/java-debug/spring-boot 를 자체 mason
  -- 레지스트리(github:nvim-java/mason-registry)로 설치하므로 그 레지스트리를
  -- 기본 레지스트리보다 먼저 등록한다. 순서: nvim-java 우선 → mason-org 폴백.
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {
      registries = {
        "github:nvim-java/mason-registry",
        "github:mason-org/mason-registry",
      },
    },
  },

  -- Mason 으로 설치한 서버를 자동으로 vim.lsp.enable() 까지 처리.
  -- jdtls 는 제외한다 — nvim-java 가 require("java").setup() + vim.lsp.enable("jdtls")
  -- 로 직접 등록/활성화하므로, 여기서 자동 enable 하면 이중 setup 충돌이 난다.
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "lua_ls",
        "ts_ls",
        "gopls",
        "rust_analyzer",
        "basedpyright",
      },
      -- jdtls 는 nvim-java 가 소유. mason-lspconfig 의 자동 enable 에서 빼둔다.
      automatic_enable = {
        exclude = { "jdtls" },
      },
    },
  },

  -- 서버별 기본 설정 데이터 (lsp/<name>.lua) 제공
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- blink.cmp가 지원하는 추가 기능을 모든 LSP 서버에 알림 (스니펫, 풍부한 completion 등)
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      -- LSP가 버퍼에 붙을 때 공통 키맵 등록
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local opts = { buffer = ev.buf, silent = true }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "<leader>f", function()
            require("conform").format({ async = true, lsp_format = "fallback" })
          end, opts)
        end,
      })

      -- 진단(diagnostic) 표시 설정
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- 서버별 커스텀 설정 (없는 서버는 nvim-lspconfig 기본값으로 자동 동작)
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            diagnostics = { globals = { "vim" } },
            telemetry = { enable = false },
          },
        },
      })
    end,
  },
}
