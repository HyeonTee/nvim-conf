local keymap = vim.keymap
local opts = { noremap = true, silent = true }

keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")

-- 검색 하이라이트 해제
keymap.set("n", "<Esc>", ":nohlsearch<CR>", opts)

-- 왼쪽 일괄 삭제
keymap.set("n", "dw", "vb_d")

-- 전체 선택
keymap.set("n", "<C-a>", "gg<S-v>G")

-- 점프리스트 앞으로 (<Tab>이 탭이동에 쓰여 <C-i>가 막히므로 별도 키 사용)
-- (<C-m> 은 Enter 와 같은 키코드라 사용하면 안 됨)
keymap.set("n", "<leader>i", "<C-i>", opts)

-- 새 탭
keymap.set("n", "te", ":tabedit<Return>", opts)
keymap.set("n", "<tab>", ":tabnext<Return>", opts)
keymap.set("n", "<s-tab>", ":tabprev<Return>", opts)

-- 화면 분할
keymap.set("n", "ss", ":split<Return>", opts)
keymap.set("n", "sv", ":vsplit<Return>", opts)

-- 분할 화면 이동
keymap.set("n", "sh", "<C-w>h")
keymap.set("n", "sk", "<C-w>k")
keymap.set("n", "sj", "<C-w>j")
keymap.set("n", "sl", "<C-w>l")

-- 화면 크기 조정
keymap.set("n", "<C-w><left>", "<C-w><")
keymap.set("n", "<C-w><right>", "<C-w>>")
keymap.set("n", "<C-w><up>", "<C-w>+")
keymap.set("n", "<C-w><down>", "<C-w>-")

-- 다음 진단
keymap.set("n", "<C-j>", function()
  vim.diagnostic.goto_next()
end, opts)

-- 터미널: 모드 탈출 및 창 이동 (mode "t" 라 노멀모드 매핑과 충돌하지 않음)
keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "터미널: 노멀 모드로" })
keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], { desc = "터미널: 왼쪽 창" })
keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], { desc = "터미널: 아래 창" })
keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], { desc = "터미널: 위 창" })
keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], { desc = "터미널: 오른쪽 창" })
