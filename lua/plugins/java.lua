-- Java / Spring Boot 개발용 플러그인 묶음 (nvim-java 기반).
--
-- 이전에는 nvim-jdtls 로 ftplugin/java.lua 에서 직접 attach 하고
-- spring-boot.nvim / java-debug / java-test 번들을 손으로 주입했지만,
-- 머신 간 jar 버전 드리프트(특히 Spring) 관리가 번거로워 nvim-java 로 이전.
--
-- nvim-java 가 jdtls·lombok·java-test·java-debug-adapter·spring-boot.nvim 을
-- 모두 자체 번들/관리하므로 ftplugin 의 수동 와이어업이 사라진다.
--
-- 핵심 주의점:
--   1. require("java").setup() 이 vim.lsp.enable("jdtls") 보다 먼저 호출돼야 함.
--   2. jdtls 는 nvim-java 의 mason 레지스트리로 설치됨 (lsp.lua 의 mason registries 참고).
--   3. mason-lspconfig 의 자동 enable 에서 jdtls 를 제외해야 이중 setup 충돌이 없음
--      (lsp.lua 의 automatic_enable.exclude 참고).
--   4. jdtls 세부 설정은 vim.lsp.config("jdtls", ...) 로 오버라이드 (아래).

return {
  {
    "nvim-java/nvim-java",
    -- java 파일을 열 때 로드. nvim-java 가 jdtls 설정을 등록하고 enable 한다.
    ft = "java",
    dependencies = {
      -- nvim-java 는 mason 레지스트리로 jdtls 등을 설치하므로 mason 이 먼저 떠 있어야 함.
      "williamboman/mason.nvim",
      -- DAP 통합(java-debug/java-test) 은 nvim-dap 위에서 동작.
      "mfussenegger/nvim-dap",
    },
    config = function()
      -- jdtls 부팅용 Java 21 탐지 (jdtls/Spring Boot LS 모두 Java 21+ 요구).
      -- PATH 의 java 가 더 낮으면 exit 13 / UnsupportedClassVersionError.
      -- 우선순위: JDTLS_JAVA_HOME → macOS java_home -v 21 → Linux /usr/lib/jvm → JAVA_HOME → PATH.
      local function find_java21()
        if vim.env.JDTLS_JAVA_HOME and vim.env.JDTLS_JAVA_HOME ~= "" then
          return vim.env.JDTLS_JAVA_HOME .. "/bin/java"
        end
        if vim.fn.has("mac") == 1 then
          local handle = io.popen("/usr/libexec/java_home -v 21 2>/dev/null")
          if handle then
            local home = handle:read("*l")
            handle:close()
            if home and home ~= "" then
              return home .. "/bin/java"
            end
          end
        elseif vim.fn.has("unix") == 1 then
          for _, pattern in ipairs({ "*temurin-21*", "*java-21-*", "*jdk-21*", "*-21-openjdk*" }) do
            for _, dir in ipairs(vim.split(vim.fn.glob("/usr/lib/jvm/" .. pattern), "\n", { trimempty = true })) do
              local bin = dir .. "/bin/java"
              if vim.fn.executable(bin) == 1 then
                return bin
              end
            end
          end
        end
        if vim.env.JAVA_HOME and vim.env.JAVA_HOME ~= "" then
          return vim.env.JAVA_HOME .. "/bin/java"
        end
        return "java"
      end

      -- 1) nvim-java 부트스트랩 (jdtls lsp config 를 등록/패치).
      require("java").setup()

      -- 2) jdtls 세부 설정 오버라이드. nvim-jdtls 시절 settings 를 그대로 이전.
      --    nvim-java 가 만든 jdtls 설정 위에 병합된다.
      local capabilities = {}
      local ok_blink, blink = pcall(require, "blink.cmp")
      if ok_blink then
        capabilities = blink.get_lsp_capabilities()
      end

      -- jdtls 부팅 JVM 의 JAVA_HOME (bin/java 에서 두 단계 상위)
      local java21_home = vim.fn.fnamemodify(find_java21(), ":h:h")

      vim.lsp.config("jdtls", {
        capabilities = capabilities,
        settings = {
          java = {
            configuration = {
              -- 프로젝트 빌드에 쓸 런타임. Spring Boot 프로젝트는 Java 21 기준.
              runtimes = {
                {
                  name = "JavaSE-21",
                  path = java21_home,
                },
              },
              updateBuildConfiguration = "automatic",
            },
            eclipse = { downloadSources = true },
            maven = { downloadSources = true },
            implementationsCodeLens = { enabled = true },
            referencesCodeLens = { enabled = true },
            signatureHelp = { enabled = true },
            -- inlay hints: 메서드 인자에 파라미터 이름을 인라인 표시.
            -- 표시 자체는 vim.lsp.inlay_hint(LspAttach, lsp.lua)에서 켠다.
            inlayHints = { parameterNames = { enabled = "all" } },
            completion = {
              favoriteStaticMembers = {
                "org.junit.Assert.*",
                "org.junit.Assume.*",
                "org.junit.jupiter.api.Assertions.*",
                "org.junit.jupiter.api.Assumptions.*",
                "org.mockito.Mockito.*",
                "org.mockito.ArgumentMatchers.*",
              },
              importOrder = { "java", "javax", "com", "org" },
            },
            sources = {
              organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 },
            },
            -- 포맷 들여쓰기 4칸 스페이스 강제 (LSP formatOptions 미전달 시 안전망).
            format = {
              enabled = true,
              tabSize = 4,
              insertSpaces = true,
            },
          },
        },
      })

      -- 3) jdtls 활성화 (java 버퍼에서 자동 attach).
      vim.lsp.enable("jdtls")
    end,
  },

  -- DAP 코어 + UI. nvim-java 가 java-debug-adapter / java-test 를 nvim-dap 에
  -- 자동 연결하므로, 여기서는 UI/가상 텍스트와 키맵만 둔다.
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
      { "theHamsta/nvim-dap-virtual-text", opts = {} },
    },
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "DAP: 브레이크포인트 토글" },
      { "<leader>dc", function() require("dap").continue() end, desc = "DAP: 계속" },
      { "<leader>di", function() require("dap").step_into() end, desc = "DAP: step into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "DAP: step over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "DAP: step out" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "DAP: 종료" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "DAP UI 토글" },
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end,
  },
}
