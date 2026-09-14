local M = {}

function M.check()
  local results = {}
  local function command(args)
    local ok, result = pcall(function()
      return vim.system(args, { text = true }):wait(10000)
    end)
    return ok and result.code == 0 and result.stdout or ""
  end
  local function add(ok, message)
    table.insert(results, { ok = ok, message = message })
  end
  for _, bin in ipairs({ "git", "curl", "tar", "unzip", "make", "cc", "npm", "rustup", "cargo", "rg", "fd" }) do
    add(vim.fn.executable(bin) == 1, bin .. " on PATH")
  end
  local node = command({ "node", "--version" })
  add((tonumber(node:match("v(%d+)")) or 0) >= 20, "Node >= 20 (" .. vim.trim(node) .. ")")
  local go = command({ "go", "version" })
  add((tonumber(go:match("go1%.(%d+)")) or 0) >= 25, "Go >= 1.25 (" .. vim.trim(go) .. ")")
  local python = command({ "python3", "-c", "import venv, ensurepip; print('OK')" })
  add(vim.trim(python) == "OK", "Python 3 venv/ensurepip")
  local version = require("config.toolchain").treesitter_cli
  local cli = command({ "tree-sitter", "--version" })
  add(cli:match("%d+%.%d+%.%d+") == version, "tree-sitter " .. version)
  return results
end

return M
