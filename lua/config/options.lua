vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- netrw 비활성화 (neo-tree 가 디렉토리 열기를 담당)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

opt.wrap = false
opt.linebreak = true

opt.ignorecase = true
opt.smartcase = true

opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8

opt.splitright = true
opt.splitbelow = true

opt.undofile = true
opt.swapfile = false

opt.clipboard = "unnamedplus"
opt.mouse = "a"

opt.updatetime = 250
opt.timeoutlen = 300

-- Undercurl
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])
