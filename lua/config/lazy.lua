local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local root = vim.env.NVIM_CONFIG_ROOT or vim.fn.stdpath("config")
-- 별도 checkout을 실행할 때 기존 ~/.config/nvim이 모듈을 가로채지 않게 한다.
if root ~= vim.fn.stdpath("config") then
  vim.opt.rtp:remove(vim.fn.stdpath("config"))
  vim.opt.rtp:remove(vim.fn.stdpath("config") .. "/after")
end
vim.opt.rtp:prepend(root)
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  assert(vim.g.ide_bootstrap, "Plugins missing. Run bash scripts/bootstrap.sh first.")
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
    }, true, {})
    error(out)
  end
end
if vim.g.ide_bootstrap then
  local lock = vim.json.decode(table.concat(vim.fn.readfile(root .. "/lazy-lock.json"), "\n"))
  local head = vim.fn.system({ "git", "-C", lazypath, "rev-parse", "HEAD" })
  if vim.trim(head) ~= lock["lazy.nvim"].commit then
    local dirty = vim.fn.system({ "git", "-C", lazypath, "status", "--porcelain", "--untracked-files=no" })
    assert(vim.v.shell_error == 0 and dirty == "", "lazy.nvim has local changes; preserve them before bootstrap")
    local fetch = vim.fn.system({ "git", "-C", lazypath, "fetch", "origin", lock["lazy.nvim"].commit })
    assert(vim.v.shell_error == 0, fetch)
    local checkout = vim.fn.system({ "git", "-C", lazypath, "checkout", "--detach", lock["lazy.nvim"].commit })
    assert(vim.v.shell_error == 0, checkout)
  end
end
vim.opt.rtp:prepend(lazypath)

local spec = { { import = "plugins" } }
if vim.g.ide_bootstrap then
  -- 설치 전에는 eager/FileType/키 이벤트를 실행하지 않는다. 설치 완료 후 필요한
  -- 플러그인만 명시적으로 로드하며, 일반 실행에서는 원래 import를 사용한다.
  local function defer(item)
    if type(item) ~= "table" then
      return item
    end
    if type(item[1]) == "string" then
      item.lazy, item.event, item.ft, item.keys, item.init = true, nil, nil, nil, nil
      if item.dependencies then
        for i, dependency in ipairs(item.dependencies) do
          item.dependencies[i] = defer(dependency)
        end
      end
    else
      for i, child in ipairs(item) do
        item[i] = defer(child)
      end
    end
    return item
  end
  spec = {}
  for _, file in ipairs(vim.fn.glob(root .. "/lua/plugins/*.lua", false, true)) do
    table.insert(spec, defer(dofile(file)))
  end
end

require("lazy").setup({
  rocks = { enabled = false },
  headless = { process = false, log = false, task = false, colors = false },
  lockfile = root .. "/lazy-lock.json",
  root = vim.fn.stdpath("data") .. "/lazy",
  spec = spec,
  install = { missing = false, colorscheme = { "catppuccin", "habamax" } },
  checker = { enabled = false },
  performance = {
    rtp = {
      reset = false,
      paths = { root, root .. "/after" },
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
