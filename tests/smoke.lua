local root = assert(vim.env.NVIM_CONFIG_ROOT)
local selected = vim.split(vim.env.NVIM_SMOKE_LANGS or "typescript,go,rust,java", ",")
local fixtures = {
  typescript = { file = "typescript/main.ts", server = "ts_ls" },
  go = { file = "go/main.go", server = "gopls" },
  rust = { file = "rust/src/main.rs", server = "rust_analyzer" },
  java = { file = "java/src/main/java/example/App.java", server = "jdtls" },
}
local function main()
  assert(
    debug.getinfo(require("config.java").setup, "S").source:sub(2) == root .. "/lua/config/java.lua",
    "Configuration was loaded from another checkout"
  )
  for _, lang in ipairs(selected) do
    local test = assert(fixtures[lang], "Unknown language: " .. lang)
    vim.api.nvim_set_current_dir(root .. "/tests/fixtures/" .. lang)
    if lang == "java" then
      vim.cmd.edit(vim.fn.fnameescape(root .. "/tests/fixtures/java/src/main/resources/application.yml"))
      assert(
        vim.wait(30000, function()
          for _, c in ipairs(vim.lsp.get_clients({ name = "spring-boot" })) do
            if c.initialized then
              return true
            end
          end
          return false
        end, 100),
        "Opening application.yml first did not initialize Spring LS"
      )
    end
    vim.cmd.edit(vim.fn.fnameescape(root .. "/tests/fixtures/" .. test.file))
    local buf = vim.api.nvim_get_current_buf()
    local client
    assert(
      vim.wait(180000, function()
        for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf, name = test.server })) do
          if c.initialized then
            client = c
            return true
          end
        end
        return false
      end, 100),
      lang .. ": LSP attach timed out"
    )
    if lang == "typescript" then
      assert(#vim.lsp.get_clients({ bufnr = buf, name = "vtsls" }) == 0, "duplicate TS LSP")
    end
    local symbols = client:request_sync(
      "textDocument/documentSymbol",
      { textDocument = { uri = vim.uri_from_bufnr(buf) } },
      60000,
      buf
    )
    assert(symbols and not symbols.err and symbols.result and #symbols.result > 0, lang .. ": document symbols failed")
    local before = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
    local format_error
    require("conform").format({ bufnr = buf, async = false, timeout_ms = 15000, lsp_format = "fallback" }, function(err)
      format_error = err
    end)
    assert(not format_error, lang .. ": " .. tostring(format_error))
    local after = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
    assert(before ~= after, lang .. ": formatter did not change deliberately unformatted fixture")
    if lang == "go" then
      assert(after:find('import "fmt"', 1, true), "goimports did not add the missing import")
    end
    vim.bo[buf].modified = false
    if lang == "java" then
      assert(
        vim.wait(30000, function()
          for _, c in ipairs(vim.lsp.get_clients({ name = "spring-boot" })) do
            if c.initialized then
              return true
            end
          end
          return false
        end, 100),
        "Spring Boot LS not initialized"
      )
    end
    print("PASS smoke " .. lang .. ": attach, symbols, formatting" .. (lang == "java" and ", Spring LS" or ""))
  end
end
local ok, err = xpcall(main, debug.traceback)
for _, client in ipairs(vim.lsp.get_clients()) do
  client:stop(true)
end
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit! 1")
end
vim.cmd("qa!")
