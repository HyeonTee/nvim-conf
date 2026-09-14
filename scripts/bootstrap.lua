local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.g.ide_bootstrap = true
vim.o.loadplugins = true
local function main()
  local local_config = root .. "/lua/config/local.lua"
  if vim.uv.fs_stat(local_config) then
    dofile(local_config)
  end
  local policy = require("config.toolchain")
  local v = vim.version()
  assert(
    string.format("%d.%d.%d", v.major, v.minor, v.patch) == policy.neovim and not v.prerelease,
    "Use the managed Neovim"
  )
  for _, result in ipairs(require("config.prerequisites").check()) do
    assert(result.ok, "Missing/incompatible prerequisite: " .. result.message .. " (see README.md)")
  end
  local lock_path = root .. "/lazy-lock.json"
  local before = vim.fn.readfile(lock_path)
  require("config.lazy")
  -- lazy install/restore가 lock을 갱신하므로 원본 내용을 복원한다.
  local ok, err = xpcall(function()
    require("lazy").install({ wait = true, lockfile = true, show = false })
    -- install은 로드된 spec만 lock에 기록한다. restore에는 원본 전체를 사용한다.
    vim.fn.writefile(before, lock_path)
    require("lazy.manage.lock")._loaded = false
    require("lazy").restore({ wait = true, show = false })
    for name, item in pairs(vim.json.decode(table.concat(before, "\n"))) do
      local path = vim.fn.stdpath("data") .. "/lazy/" .. name
      local result = vim.system({ "git", "-C", path, "rev-parse", "HEAD" }, { text = true }):wait()
      assert(result.code == 0 and vim.trim(result.stdout) == item.commit, "Plugin restore failed: " .. name)
    end
  end, debug.traceback)
  vim.fn.writefile(before, lock_path)
  assert(ok, err)
  -- blink.cmp fuzzy는 로컬 빌드로 고정한다. 다운로드본이 남긴 태그 version 파일이나
  -- 옛 커밋의 빌드 표시가 남아 있으면 실행 시 Lua 구현으로 폴백하므로 정리하고 다시 빌드한다.
  local blink_dir = vim.fn.stdpath("data") .. "/lazy/blink.cmp"
  local release = blink_dir .. "/target/release"
  local blink_lib = release .. "/libblink_cmp_fuzzy." .. (vim.fn.has("mac") == 1 and "dylib" or "so")
  local blink_head = vim.system({ "git", "-C", blink_dir, "rev-parse", "HEAD" }, { text = true }):wait()
  assert(blink_head.code == 0, "Failed to read blink.cmp HEAD")
  blink_head = vim.trim(blink_head.stdout)
  local marker_file = io.open(release .. "/version")
  local marker = marker_file and vim.trim(marker_file:read("*a")) or nil
  if marker_file then
    marker_file:close()
  end
  if vim.uv.fs_stat(blink_lib) == nil or not (marker == nil or marker == blink_head) then
    if marker ~= nil then
      assert(vim.fn.delete(release .. "/version") == 0, "Failed to remove stale blink.cmp version marker")
    end
    print("Building blink.cmp fuzzy library")
    local build = vim.system({ "cargo", "build", "--release" }, { cwd = blink_dir, text = true }):wait(900000)
    assert(build.code == 0, "blink.cmp fuzzy build failed: " .. (build.stderr or ""))
  end
  assert(vim.uv.fs_stat(blink_lib), "blink.cmp fuzzy library missing after build")
  require("mason").setup()
  local registry = require("mason-registry")
  local refreshed, success = false, false
  registry.refresh(function(ok_refresh)
    success, refreshed = ok_refresh, true
  end)
  assert(vim.wait(120000, function()
    return refreshed
  end, 50) and success, "Mason registry refresh failed")
  for name, version in pairs(policy.mason) do
    local pkg = registry.get_package(name)
    local current = pkg:get_installed_version()
    if current ~= version then
      print("Installing " .. name .. "@" .. version .. " (was " .. tostring(current) .. ")")
      local done = false
      pkg:install({ version = version }, function()
        done = true
      end)
      assert(
        vim.wait(600000, function()
          return done
        end, 100),
        "Timed out: " .. name
      )
      assert(pkg:get_installed_version() == version, "Installation failed: " .. name)
    end
  end
  local ts_dir = vim.fn.stdpath("data") .. "/mason/packages/typescript-language-server"
  local ts_json = ts_dir .. "/node_modules/typescript/package.json"
  local ts = vim.json.decode(table.concat(vim.fn.readfile(ts_json), "\n"))
  if ts.version ~= policy.typescript then
    local result = vim
      .system({ "npm", "install", "--prefix", ts_dir, "--save-exact", "typescript@" .. policy.typescript }, { text = true })
      :wait(120000)
    assert(result.code == 0, result.stderr)
  end
  require("nvim-treesitter").install(policy.parsers):wait(300000)
  require("nvim-treesitter").update(policy.parsers):wait(300000)
  for _, lang in ipairs(policy.parsers) do
    assert(pcall(vim.treesitter.language.add, lang), "Missing parser: " .. lang)
    local revision = require("nvim-treesitter.parsers")[lang].install_info.revision
    if revision then
      local path = vim.fn.stdpath("data") .. "/site/parser-info/" .. lang .. ".revision"
      assert(vim.trim(table.concat(vim.fn.readfile(path))) == revision, "Parser update failed: " .. lang)
    end
  end
  require("lazy").load({ plugins = { "nvim-java" } })
  assert(vim.lsp.is_enabled("jdtls"), "Java setup failed; inspect errors above")
  local java_home = require("pkgm.resolve").get_jdk_home(vim.g.nvim_java_config)
  assert(
    require("config.java").version(java_home) == policy.java.jdk.version,
    "Installed Java launch JDK version mismatch"
  )
  print("Plugins, Mason tools, parsers and Java bundles installed.")
end
local ok, err = xpcall(main, debug.traceback)
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("qa!")
