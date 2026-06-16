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

          -- inlay hints: 서버가 지원하면 기본 ON, <leader>uh 로 버퍼별 토글.
          -- (jdtls 파라미터 이름 힌트는 java.lua 의 inlayHints 설정에서 켠다)
          --
          -- ⚠ Neovim 0.13-dev(nightly) inlay hint 구현에 편집 중 레이스가 있다:
          --   힌트 col 은 "응답 도착 시점의 줄"로 계산되는데 그리기는 "redraw 시점의 줄"에
          --   대해 일어나, 타이핑으로 줄이 짧아지면 col 이 줄 길이를 넘어가
          --   "Invalid 'col': out of range" 로 데코레이션 프로바이더가 크래시한다.
          --   회피: insert 모드 동안은 렌더를 끄고(버퍼가 흔들리는 구간) 빠져나오면
          --   안정된 버퍼에 다시 켠다. 사용자의 on/off 의도는 b:inlay_hints_on 으로 보존.
          --   (코어가 고쳐지면 이 가드는 제거 가능)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client:supports_method("textDocument/inlayHint") then
            local buf = ev.buf
            vim.b[buf].inlay_hints_on = true
            vim.lsp.inlay_hint.enable(true, { bufnr = buf })

            vim.keymap.set("n", "<leader>uh", function()
              local on = not vim.b[buf].inlay_hints_on
              vim.b[buf].inlay_hints_on = on
              vim.lsp.inlay_hint.enable(on, { bufnr = buf })
            end, vim.tbl_extend("force", opts, { desc = "UI: inlay hints 토글" }))

            local grp = vim.api.nvim_create_augroup("InlayHintInsertGuard_" .. buf, { clear = true })
            vim.api.nvim_create_autocmd("InsertEnter", {
              group = grp,
              buffer = buf,
              callback = function()
                vim.lsp.inlay_hint.enable(false, { bufnr = buf })
              end,
            })
            vim.api.nvim_create_autocmd("InsertLeave", {
              group = grp,
              buffer = buf,
              callback = function()
                if vim.b[buf].inlay_hints_on then
                  vim.lsp.inlay_hint.enable(true, { bufnr = buf })
                end
              end,
            })
          end
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
