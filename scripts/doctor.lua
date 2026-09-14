local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
local data = vim.fn.stdpath("data")
for _, path in ipairs(vim.fn.glob(data .. "/lazy/*", false, true)) do
  vim.opt.rtp:append(path)
end
vim.opt.rtp:append(data .. "/site")
vim.opt.rtp:append(root .. "/after")
local failures, warnings = 0, 0
local function check(ok, message)
  print((ok and "PASS " or "FAIL ") .. message)
  if not ok then
    failures = failures + 1
  end
end
local function warn(message)
  warnings = warnings + 1
  print("WARN " .. message)
end
local function main()
  local policy = require("config.toolchain")
  local local_file = root .. "/lua/config/local.lua"
  if vim.uv.fs_stat(local_file) then
    dofile(local_file)
  end
  local v = vim.version()
  check(
    string.format("%d.%d.%d", v.major, v.minor, v.patch) == policy.neovim and not v.prerelease,
    "Neovim " .. policy.neovim
  )
  for _, result in ipairs(require("config.prerequisites").check()) do
    check(result.ok, result.message)
  end
  local lock = vim.json.decode(table.concat(vim.fn.readfile(root .. "/lazy-lock.json"), "\n"))
  for name, item in pairs(lock) do
    local result = vim.system({ "git", "-C", data .. "/lazy/" .. name, "rev-parse", "HEAD" }, { text = true }):wait()
    local dirty = vim
      .system({ "git", "-C", data .. "/lazy/" .. name, "status", "--porcelain", "--untracked-files=no" }, { text = true })
      :wait()
    check(
      result.code == 0 and vim.trim(result.stdout) == item.commit and dirty.code == 0 and dirty.stdout == "",
      "plugin " .. name .. " clean locked commit"
    )
  end
  require("mason").setup({ registries = { "github:mason-org/mason-registry" } })
  local registry = require("mason-registry")
  local ffi = require("ffi")
  check(pcall(ffi.load, data .. "/lazy/telescope-fzf-native.nvim/build/libfzf.so"), "Telescope native library")
  local extension = vim.fn.has("mac") == 1 and "dylib" or "so"
  -- blink은 version 파일로 fuzzy 구현을 고른다. 로컬 빌드는 플러그인 HEAD sha를 남기고,
  -- 다운로드본은 태그를 남긴다. download 비활성 상태에서 태그나 옛 sha가 남아 있으면
  -- 라이브러리가 로드되더라도 런타임에 Lua로 폴백하므로 함께 검사한다.
  local blink_dir = data .. "/lazy/blink.cmp"
  local blink_head = vim.system({ "git", "-C", blink_dir, "rev-parse", "HEAD" }, { text = true }):wait()
  local blink_version = io.open(blink_dir .. "/target/release/version")
  local blink_marker = blink_version and vim.trim(blink_version:read("*a")) or nil
  if blink_version then
    blink_version:close()
  end
  check(
    pcall(ffi.load, blink_dir .. "/target/release/libblink_cmp_fuzzy." .. extension)
      and (blink_marker == nil or (blink_head.code == 0 and blink_marker == vim.trim(blink_head.stdout))),
    "Blink native library (rust fuzzy active)"
  )
  for name, version in pairs(policy.mason) do
    local ok, pkg = pcall(registry.get_package, name)
    local actual = ok and pkg:get_installed_version() or nil
    check(actual == version, name .. " " .. version .. " (installed " .. tostring(actual) .. ")")
  end
  local ts_path = data .. "/mason/packages/typescript-language-server/node_modules/typescript/package.json"
  local ts_ok, ts = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(ts_path), "\n"))
  end)
  check(ts_ok and ts.version == policy.typescript, "bundled TypeScript " .. policy.typescript)
  -- 서버를 띄우지 않고 실제 Mason 자동 활성화 필터를 검사한다.
  local spec = dofile(root .. "/lua/plugins/lsp.lua")
  require("mason-lspconfig.settings").set(spec[3].opts)
  require("mason-lspconfig.features.automatic_enable").init()
  check(vim.lsp.is_enabled("ts_ls") and not vim.lsp.is_enabled("vtsls"), "single TypeScript server")
  check(not vim.lsp.is_enabled("jdtls") and not vim.lsp.is_enabled("rust_analyzer"), "Mason does not own Java/Rust")
  for _, lang in ipairs(policy.parsers) do
    local ok, err = pcall(function()
      assert(vim.treesitter.language.add(lang))
      local revision = require("nvim-treesitter.parsers")[lang].install_info.revision
      if revision then
        local path = data .. "/site/parser-info/" .. lang .. ".revision"
        assert(vim.trim(table.concat(vim.fn.readfile(path))) == revision, "parser revision differs from lock")
      end
      for _, query in ipairs({ "highlights", "injections", "indents", "textobjects" }) do
        vim.treesitter.query.get(lang, query)
      end
    end)
    check(ok, "parser/queries " .. lang .. (ok and "" or ": " .. tostring(err)))
  end
  local java = require("config.java")
  java.pin_jdk()
  local manager = require("pkgm.manager")()
  for name, key in pairs({
    jdtls = "jdtls",
    lombok = "lombok",
    ["java-test"] = "java_test",
    ["java-debug"] = "java_debug_adapter",
    ["spring-boot-tools"] = "spring_boot_tools",
  }) do
    check(
      manager:is_installed(name, policy.java[key].version),
      "Java bundle " .. name .. "@" .. policy.java[key].version
    )
  end
  local jdk_ok, java_opts = pcall(java.options)
  check(
    jdk_ok and java.version(java_opts.jdk.path) == policy.java.jdk.version,
    "Java launch JDK " .. policy.java.jdk.version
  )
  local runtimes, errors = java.runtimes()
  for _, err in ipairs(errors) do
    check(false, err)
  end
  local java21 = false
  for _, runtime in ipairs(runtimes) do
    print("INFO " .. runtime.name .. " = " .. runtime.path)
    java21 = java21 or runtime.name == "JavaSE-21"
  end
  if not java21 then
    warn("Project JDK 21 missing; install it and set JAVA21_HOME for Java 21 projects")
  end
  for _, component in ipairs({ "rust-analyzer", "rustfmt", "clippy-driver" }) do
    local result = vim.system({ "rustup", "which", component }, { text = true }):wait()
    check(result.code == 0, "active Rust toolchain: " .. component)
  end
  local sysroot = vim.system({ "rustc", "--print", "sysroot" }, { text = true }):wait()
  check(
    sysroot.code == 0 and vim.uv.fs_stat(vim.trim(sysroot.stdout) .. "/lib/rustlib/src/rust/library") ~= nil,
    "active Rust toolchain: rust-src"
  )
  if
    vim.fn.has("mac") == 0
    and vim.fn.executable("wl-copy") == 0
    and vim.fn.executable("xclip") == 0
    and vim.fn.executable("xsel") == 0
  then
    warn("No desktop clipboard provider; install wl-clipboard or xclip when using a desktop")
  end
end
local ok, err = xpcall(main, debug.traceback)
if not ok then
  check(false, err)
end
print(string.format("doctor: %d failure(s), %d warning(s). No tools installed or updated.", failures, warnings))
if failures > 0 then
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
