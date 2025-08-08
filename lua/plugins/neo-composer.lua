return {
  "ecthelionvi/NeoComposer.nvim",
  dependencies = { "kkharji/sqlite.lua" },
  event = "VeryLazy",
  config = function()
    -- Set up NeoComposer with minimal noise and defaults
    require("NeoComposer").setup({
      notify = false, -- reduce popup noise
    })

    -- If Telescope is available, load the macros extension
    pcall(function()
      require("telescope").load_extension("macros")
    end)
  end,
}
