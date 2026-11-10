return {
  {
    "smart-splits-nvim/smart-splits.nvim",
    lazy = false,
    dependencies = {
      { "smart-splits-nvim/backend-wezterm", main = "smart-splits-backend-wezterm", opts = {} },
    },
    opts = {
      mux = { backend = "smart-splits-backend-wezterm" },
    },
    keys = {
      { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Move to left split" },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Move to lower split" },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Move to upper split" },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Move to right split" },
      { "<C-A-h>", function() require("smart-splits").resize_left() end, desc = "Resize split left" },
      { "<C-A-j>", function() require("smart-splits").resize_down() end, desc = "Resize split down" },
      { "<C-A-k>", function() require("smart-splits").resize_up() end, desc = "Resize split up" },
      { "<C-A-l>", function() require("smart-splits").resize_right() end, desc = "Resize split right" },
    },
  },
}
