-- nvim-treesitter `main` branch
-- master 와 달리 setup({highlight=...}) 가 없다.
-- 파서는 install() 로 깔고, highlight/indent 는 FileType 에서 직접 켠다.
--
-- 요구사항 (둘 중 하나라도 없으면 하이라이트가 안 켜진다):
--   1. Neovim 0.12+ (nightly) — main 이 vim.list 등 0.12 API 사용. 0.11.x 는 install() 가 크래시.
--   2. `tree-sitter` CLI — main 은 파서를 소스에서 컴파일하므로 PATH 에 필요.
-- macOS: brew install neovim --HEAD && brew install tree-sitter-cli
-- 파서/쿼리는 ~/.local/share/nvim/site/ (기본 rtp) 에 설치된다.

local parsers = {
  "lua",
  "vim",
  "vimdoc",
  "query",
  "go",
  "gomod",
  "gosum",
  "rust",
  "python",
  "typescript",
  "javascript",
  "tsx",
  "json",
  "yaml",
  "toml",
  "html",
  "css",
  "markdown",
  "markdown_inline",
  "bash",
  "gitignore",
  "sql",
  "regex",
  "java",
  "properties",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install(parsers)

      -- 파서가 있는 버퍼면 highlight + indent 를 켠다.
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(ev)
          local ft = vim.bo[ev.buf].filetype
          local lang = vim.treesitter.language.get_lang(ft)
          if not lang then
            return
          end
          if not pcall(vim.treesitter.start, ev.buf, lang) then
            return
          end
          -- treesitter 기반 indent (experimental)
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
        },
        move = {
          set_jumps = true,
        },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")

      -- select
      local selects = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
      }
      for key, obj in pairs(selects) do
        vim.keymap.set({ "x", "o" }, key, function()
          select.select_textobject(obj, "textobjects")
        end, { desc = "Select " .. obj })
      end

      -- move
      vim.keymap.set({ "n", "x", "o" }, "]f", function()
        move.goto_next_start("@function.outer", "textobjects")
      end, { desc = "Next function start" })
      vim.keymap.set({ "n", "x", "o" }, "]]", function()
        move.goto_next_start("@class.outer", "textobjects")
      end, { desc = "Next class start" })
      vim.keymap.set({ "n", "x", "o" }, "[f", function()
        move.goto_previous_start("@function.outer", "textobjects")
      end, { desc = "Prev function start" })
      vim.keymap.set({ "n", "x", "o" }, "[[", function()
        move.goto_previous_start("@class.outer", "textobjects")
      end, { desc = "Prev class start" })
    end,
  },
}
