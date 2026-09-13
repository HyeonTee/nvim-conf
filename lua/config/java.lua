local M = {}

function M.pin_jdk()
  local version = require("config.toolchain").java.jdk.version
  local major = assert(version:match("^(%d+)"))
  local specs = require("pkgm.specs.init")
  for _, spec in ipairs(specs) do
    if spec:get_name() == "openjdk" and spec:get_version() == version then
      return
    end
  end
  local BaseSpec = require("pkgm.specs.base-spec")
  local urls = {}
  for os, suffix in pairs({ mac = "macos", linux = "linux" }) do
    urls[os] = {}
    for arch, asset in pairs({ arm = "aarch64", x86 = "x64" }) do
      urls[os][arch] = {
        ["64bit"] = "https://download.oracle.com/java/"
          .. major
          .. "/archive/jdk-"
          .. version
          .. "_"
          .. suffix
          .. "-"
          .. asset
          .. "_bin.tar.gz",
      }
    end
  end
  table.insert(specs, 1, BaseSpec({ name = "openjdk", version = version, urls = urls }))
end

function M.version(home)
  if not home or vim.fn.executable(home .. "/bin/java") ~= 1 then
    return nil
  end
  local result = vim.system({ home .. "/bin/java", "-version" }, { text = true }):wait(10000)
  if result.code ~= 0 then
    return nil
  end
  return ((result.stderr or "") .. (result.stdout or "")):match('version "?([%d.]+)')
end

function M.major(home)
  return tonumber((M.version(home) or ""):match("^(%d+)"))
end

-- 런타임 이름과 실제 JDK major가 일치할 때만 등록한다.
function M.runtimes()
  local runtimes, errors = {}, {}
  for _, major in ipairs({ 17, 21, 25 }) do
    local env_name = "JAVA" .. major .. "_HOME"
    local explicit = vim.env[env_name]
    local candidates = {}
    if explicit and explicit ~= "" then
      candidates = { explicit }
    else
      if vim.fn.has("mac") == 1 then
        local result = vim.system({ "/usr/libexec/java_home", "-v", tostring(major) }, { text = true }):wait()
        if result.code == 0 then
          table.insert(candidates, vim.trim(result.stdout))
        end
      end
      if vim.env.JAVA_HOME then
        table.insert(candidates, vim.env.JAVA_HOME)
      end
      for _, pattern in ipairs({
        "/usr/lib/jvm/*",
        "/opt/homebrew/opt/openjdk@" .. major .. "/libexec/openjdk.jdk/Contents/Home",
        "/usr/local/opt/openjdk@" .. major .. "/libexec/openjdk.jdk/Contents/Home",
      }) do
        vim.list_extend(candidates, vim.fn.glob(pattern, false, true))
      end
    end
    for _, home in ipairs(candidates) do
      if M.major(home) == major then
        table.insert(runtimes, { name = "JavaSE-" .. major, path = home })
        break
      elseif explicit then
        table.insert(errors, env_name .. " must point to an executable Java " .. major .. " JDK: " .. home)
      end
    end
  end
  return runtimes, errors
end

function M.options()
  M.pin_jdk()
  local opts = vim.deepcopy(require("config.toolchain").java)
  local package_root = vim.fn.stdpath("data") .. "/nvim-java/packages/openjdk/"
  -- 이전 nvim-java의 major-only 디렉터리도 실제 patch 버전이 같으면 재사용한다.
  for _, pattern in ipairs({
    package_root .. opts.jdk.version .. "/jdk-*/Contents/Home",
    package_root .. opts.jdk.version .. "/jdk-*",
    package_root .. "25/jdk-*/Contents/Home",
    package_root .. "25/jdk-*",
  }) do
    for _, home in ipairs(vim.fn.glob(pattern, false, true)) do
      if M.version(home) == opts.jdk.version then
        opts.jdk.path = home
        break
      end
    end
    if opts.jdk.path then
      break
    end
  end
  -- 일반 실행에서는 설치된 패키지만 읽는다.
  if not vim.g.ide_bootstrap then
    local defaults = require("java.config")
    local resolver = require("pkgm.resolve")
    local config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts)
    for name, key in pairs({
      jdtls = "jdtls",
      ["java-test"] = "java_test",
      ["java-debug"] = "java_debug_adapter",
      ["spring-boot-tools"] = "spring_boot_tools",
    }) do
      opts[key].path = name == "jdtls" and resolver.get_install_dir(name, config[key])
        or resolver.get_extension_root(name, config[key])
    end
    opts.lombok.path = resolver.get_lombok_path(config)
    opts.jdk.path = resolver.get_jdk_home(config)
    assert(
      opts.jdk.path ~= "" and M.version(opts.jdk.path) == opts.jdk.version,
      "Java tools missing or wrong JDK version; run bash scripts/bootstrap.sh"
    )
  end
  return opts
end

function M.setup()
  local runtimes, errors = M.runtimes()
  assert(#errors == 0, table.concat(errors, "\n"))
  local opts = M.options()
  -- Spring은 JAVA_HOME을 직접 읽으므로 실행 바이너리를 같은 관리 JDK로 지정한다.
  require("spring_boot.util").java_bin = function()
    return require("pkgm.resolve").get_jdk_home(vim.g.nvim_java_config) .. "/bin/java"
  end
  require("java").setup(opts)
  vim.lsp.config("jdtls", {
    settings = { java = { configuration = { runtimes = runtimes } } },
  })
end

return M
