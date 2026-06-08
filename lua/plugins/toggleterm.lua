-- 통합 터미널. <C-\> 로 어디서든 떴다 사라지는 플로팅 터미널 토글.
-- 터미널 모드 탈출(<Esc>)·창 이동(<C-hjkl>)·startinsert 는 글로벌로 처리되므로
-- (lua/config/keymaps.lua, autocmds.lua) 여기서는 토글/lazygit 만 다룬다.
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = {
    { "<C-\\>", desc = "터미널 토글(플로팅)" },
    { "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "터미널: 가로 분할" },
    { "<leader>tv", "<cmd>ToggleTerm direction=vertical size=80<cr>", desc = "터미널: 세로 분할" },
    { "<leader>tg", desc = "lazygit" },
  },
  opts = {
    open_mapping = [[<C-\>]], -- 어디서든 Ctrl+\ 로 토글
    direction = "float", -- 기본은 플로팅
    float_opts = { border = "curved" },
    start_in_insert = true,
    persist_size = true,
  },
  config = function(_, opts)
    require("toggleterm").setup(opts)

    -- lazygit 전용 플로팅 터미널 (lazygit 설치 필요: brew install lazygit)
    local Terminal = require("toggleterm.terminal").Terminal
    local lazygit = Terminal:new({ cmd = "lazygit", direction = "float", hidden = true })
    vim.keymap.set("n", "<leader>tg", function()
      lazygit:toggle()
    end, { desc = "lazygit", silent = true })
  end,
}
