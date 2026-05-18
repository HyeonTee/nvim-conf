-- Java / Spring Boot 개발용 플러그인 묶음.
--
-- jdtls(Eclipse JDT LS)는 일반 LSP 와 달리 워크스페이스 디렉토리, OS 별 launcher,
-- DAP/Test bundle 주입, Lombok javaagent 등 와이어업이 많아서
-- ftplugin/java.lua 에서 nvim-jdtls 를 통해 직접 attach 한다.
--
-- 실제 jdtls 설정은 ftplugin/java.lua 참고.

return {
  -- jdtls 어댑터: jdtls 바이너리(Mason 설치)를 Neovim 에서 띄우고
  -- organize_imports / extract_variable / test_class 등 전용 커맨드 제공.
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
  },

  -- Spring Boot LSP (vscode-spring-boot / STS4) 통합.
  -- bean 점프, @RequestMapping 심볼 검색, application.yml/properties 자동완성.
  -- jdtls 의 init_options.bundles 에 Spring 확장 jar 를 자동 주입.
  --
  -- java_cmd: Spring Boot LS 는 Java 21 로 빌드돼 있어 PATH 의 구버전 java
  -- (예: brew openjdk@17) 로는 UnsupportedClassVersionError 가 난다.
  -- /usr/libexec/java_home -v 21 결과를 명시적으로 지정.
  {
    "JavaHello/spring-boot.nvim",
    ft = { "java", "yaml", "jproperties" },
    dependencies = { "mfussenegger/nvim-jdtls" },
    opts = {
      java_cmd = "/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home/bin/java",
    },
  },

  -- DAP 코어 + UI. java-debug-adapter 와 java-test bundle 은 jdtls 의
  -- bundles 로 주입되며, jdtls.setup_dap() 가 호출되면 자동 구성된다.
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

  -- Java 관련 Mason 패키지를 한 곳에서 자동 설치.
  -- jdtls 도 여기서 관리 (mason-lspconfig 가 아니라) — nvim-jdtls 가 직접 attach 하므로
  -- mason-lspconfig 의 자동 enable 흐름을 거치지 않는 게 깔끔.
  -- lazy = false 로 nvim 시작 즉시 로드되어야 첫 java 버퍼 열기 전에 설치가 시작됨.
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    lazy = false,
    opts = {
      ensure_installed = {
        "jdtls",
        "java-debug-adapter",
        "java-test",
        "vscode-spring-boot-tools",
      },
      run_on_start = true,
      auto_update = false,
    },
  },
}
