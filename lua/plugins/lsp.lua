local toolchain = require("config.toolchain")

return {
  -- Java는 nvim-java, Rust는 rustup이 관리한다.
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = {
      registries = {
        "github:mason-org/mason-registry",
      },
    },
  },

  -- 설치는 scripts/bootstrap.sh에서 버전을 비교하고 명시적으로 수행한다.
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {},
      auto_update = false,
      run_on_start = false,
    },
  },

  -- Mason 으로 설치한 서버를 자동으로 vim.lsp.enable() 까지 처리.
  -- jdtls 는 제외한다 — nvim-java 가 require("java").setup() + vim.lsp.enable("jdtls")
  -- 로 직접 등록/활성화하므로, 여기서 자동 enable 하면 이중 setup 충돌이 난다.
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {},
      -- 기존 머신에 vtsls 등이 설치돼 있어도 의도한 서버만 활성화한다.
      automatic_enable = toolchain.servers,
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

      -- python: basedpyright = 타입 검사/정의 이동/자동완성, ruff = 린트/import 정리.
      -- 두 서버가 겹치는 기능은 한쪽을 꺼서 중복 진단/중복 code action 을 막는다.
      vim.lsp.config("basedpyright", {
        settings = {
          basedpyright = {
            -- import 정리는 ruff 가 담당
            disableOrganizeImports = true,
            -- 기본값 "recommended" 는 지나치게 엄격해서 일반 프로젝트에선 노이즈가 많음
            analysis = { typeCheckingMode = "standard" },
          },
        },
      })
      vim.lsp.config("ruff", {
        on_attach = function(client)
          -- hover 는 basedpyright 것만 사용
          client.server_capabilities.hoverProvider = false
        end,
      })
      local rustup = vim.fn.exepath("rustup")
      if rustup ~= "" then
        -- Mason PATH보다 우선하는 rustup proxy. 프로젝트 toolchain override를 따른다.
        vim.lsp.config("rust_analyzer", {
          cmd = { vim.fs.joinpath(vim.fs.dirname(rustup), "rust-analyzer") },
          settings = { ["rust-analyzer"] = { check = { command = "clippy" } } },
        })
        vim.lsp.enable("rust_analyzer")
      end
    end,
  },
}
