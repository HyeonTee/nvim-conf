-- java 버퍼별 설정.
--
-- jdtls attach 는 더 이상 여기서 하지 않는다. nvim-java 가
-- vim.lsp.enable("jdtls") 로 java 버퍼에 자동 attach 한다 (lua/plugins/java.lua 참고).
-- 여기서는 버퍼 단위 들여쓰기와 java 전용 키맵(nvim-java API)만 둔다.

-- Java 버퍼 들여쓰기: 4칸 스페이스 (Java 커뮤니티 표준 / Eclipse 기본).
-- 전역 옵션은 4칸이지만 버퍼 단위로 명시해 어떤 ftplugin/포매터가 덮어써도 유지.
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.expandtab = true

-- java 전용 키맵. nvim-java 의 Lua API 를 직접 호출한다.
-- (이전 nvim-jdtls 의 organize_imports/extract_*/test 와 1:1 대응)
local opts = { buffer = 0, silent = true }
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
end

-- import 정리: nvim-java 에 전용 API 가 없어 표준 LSP code action(source.organizeImports)로 처리.
map("n", "<leader>jo", function()
  vim.lsp.buf.code_action({
    context = { only = { "source.organizeImports" }, diagnostics = {} },
    apply = true,
  })
end, "Java: import 정리")

-- 리팩터링 (노멀: 커서 위치 / 비주얼: 선택 영역 — nvim-java 가 모드로 알아서 처리)
map({ "n", "v" }, "<leader>jv", function() require("java").refactor.extract_variable() end, "Java: 변수 추출")
map({ "n", "v" }, "<leader>jc", function() require("java").refactor.extract_constant() end, "Java: 상수 추출")
map("v", "<leader>jm", function() require("java").refactor.extract_method() end, "Java: 메서드 추출")

-- 테스트 러너 (DAP 연동은 nvim-java 가 자동 구성)
map("n", "<leader>jt", function() require("java").test.run_current_class() end, "Java: 클래스 테스트")
map("n", "<leader>jn", function() require("java").test.run_current_method() end, "Java: 가장 가까운 메서드 테스트")

-- main 클래스 실행
map("n", "<leader>jr", function() require("java").runner.built_in.run_app() end, "Java: main 실행")
