local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
local function main()
  local java = require("config.java")
  local version, glob, has = java.version, vim.fn.glob, vim.fn.has
  local original_env = { vim.env.JAVA17_HOME, vim.env.JAVA21_HOME, vim.env.JAVA25_HOME, vim.env.JAVA_HOME }
  java.version = function(home)
    return home == "/wrong" and "26.0.2" or "21.0.10"
  end
  vim.fn.glob = function()
    return {}
  end
  vim.fn.has = function()
    return 0
  end
  vim.env.JAVA17_HOME, vim.env.JAVA25_HOME, vim.env.JAVA_HOME = nil, nil, nil
  vim.env.JAVA21_HOME = "/wrong"
  local runtimes, errors = java.runtimes()
  assert(#runtimes == 0 and #errors == 1, "Wrong JDK must not be registered as JavaSE-21")
  vim.env.JAVA21_HOME = "/correct"
  runtimes, errors = java.runtimes()
  assert(#errors == 0 and #runtimes == 1 and runtimes[1].name == "JavaSE-21")
  java.version, vim.fn.glob, vim.fn.has = version, glob, has
  vim.env.JAVA17_HOME, vim.env.JAVA21_HOME, vim.env.JAVA25_HOME, vim.env.JAVA_HOME = unpack(original_env, 1, 4)
  local policy = require("config.toolchain")
  assert(vim.list_contains(policy.servers, "ts_ls") and not vim.list_contains(policy.servers, "vtsls"))
  assert(not vim.list_contains(policy.servers, "jdtls") and not vim.list_contains(policy.servers, "rust_analyzer"))
  local files = vim.fn.glob(root .. "/lua/**/*.lua", false, true)
  for _, f in ipairs(files) do
    assert(loadfile(f))
  end
  print("PASS regression: JDK validation, server ownership, Lua syntax")
end
local ok, err = xpcall(main, debug.traceback)
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("qa!")
