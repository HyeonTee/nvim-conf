return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, silent = true })
        end

        -- 네비게이션
        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "다음 hunk")
        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "이전 hunk")

        -- 액션
        map("n", "<leader>hs", gs.stage_hunk, "Stage hunk (다시 누르면 unstage)")
        map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
        map("n", "<leader>hS", gs.stage_buffer, "버퍼 전체 stage")
        map("n", "<leader>hp", gs.preview_hunk, "Hunk 미리보기")
        map("n", "<leader>hb", function()
          gs.blame_line({ full = true })
        end, "줄 blame")
        map("n", "<leader>hd", gs.diffthis, "Diff vs index")
      end,
    },
  },
}
