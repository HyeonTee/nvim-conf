-- 심볼 아웃라인 사이드바.
-- LSP(jdtls 등)의 documentSymbol 을 트리로 보여준다 (IntelliJ Structure / VSCode Outline 대응).
-- Java 처럼 클래스 하나가 수백 줄 되는 언어에서 메서드/클래스 구조 파악·점프에 유용.
return {
  "stevearc/aerial.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
  keys = {
    { "<leader>o", "<cmd>AerialToggle!<cr>", desc = "심볼 아웃라인 토글" },
  },
  opts = {
    -- LSP(jdtls documentSymbol) 우선, 없으면 treesitter 로 폴백.
    backends = { "lsp", "treesitter", "markdown", "man" },
    layout = {
      default_direction = "right",
      min_width = 30,
    },
    -- 코드에서 커서가 있는 심볼을 아웃라인에서 자동 강조/추적.
    highlight_on_hover = true,
    show_guides = true,
    -- 아웃라인 사이드바 내부 기본 키:
    --   <CR> 점프 / p 미리보기 / { } 이전·다음 / o za 접기 토글 / q 닫기
  },
}
