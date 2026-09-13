-- nvim-java의 고정 번들/관리 JDK를 사용한다. 프로젝트 JDK는 config.java가 검증한다.
return {
  {
    "nvim-java/nvim-java",
    ft = { "java" },
    event = { "BufReadPost application*.yml", "BufReadPost application*.yaml", "BufReadPost application*.properties" },
    dependencies = {
      "mfussenegger/nvim-dap",
      "neovim/nvim-lspconfig",
      "MunifTanjim/nui.nvim",
      -- 첫 설치에서는 아직 nvim-java의 lazy.lua를 읽을 수 없으므로 명시한다.
      "JavaHello/spring-boot.nvim",
    },
    config = function()
      require("config.java").setup()
      -- 고정된 Spring 핸들러의 nil 결과/오류 반환을 LSP 응답 규약에 맞춘다.
      vim.lsp.handlers["workspace/executeClientCommand"] = function(_, params, ctx)
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        local handler = (client and client.commands and client.commands[params.command])
          or vim.lsp.commands[params.command]
        if not handler then
          return nil, { code = -32601, message = "Unsupported command: " .. params.command }
        end
        local ok, result = pcall(handler, params.arguments, ctx)
        if not ok then
          return nil, { code = -32603, message = tostring(result) }
        end
        return result == nil and vim.NIL or result
      end
      vim.lsp.config("jdtls", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
        settings = {
          java = {
            configuration = { updateBuildConfiguration = "automatic" },
            eclipse = { downloadSources = true },
            maven = { downloadSources = true },
            implementationsCodeLens = { enabled = true },
            referencesCodeLens = { enabled = true },
            signatureHelp = { enabled = true },
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
            sources = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 } },
            format = { enabled = true, tabSize = 4, insertSpaces = true },
          },
        },
      })
      vim.lsp.enable("jdtls")
    end,
  },
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
      { "theHamsta/nvim-dap-virtual-text", opts = {} },
    },
    keys = {
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "DAP: 브레이크포인트 토글",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "DAP: 계속",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "DAP: step into",
      },
      {
        "<leader>do",
        function()
          require("dap").step_over()
        end,
        desc = "DAP: step over",
      },
      {
        "<leader>dO",
        function()
          require("dap").step_out()
        end,
        desc = "DAP: step out",
      },
      {
        "<leader>dt",
        function()
          require("dap").terminate()
        end,
        desc = "DAP: 종료",
      },
      {
        "<leader>du",
        function()
          require("dapui").toggle()
        end,
        desc = "DAP UI 토글",
      },
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },
}
