require("config.options")
local local_config = (vim.env.NVIM_CONFIG_ROOT or vim.fn.stdpath("config")) .. "/lua/config/local.lua"
if vim.uv.fs_stat(local_config) then
  dofile(local_config)
end
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
