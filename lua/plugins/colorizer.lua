return {
	"norcalli/nvim-colorizer.lua",
	-- I'm replacing this plugin with mini-hipatterns, installed as a LazyExtra
	enabled = true,
	config = function()
		require("colorizer").setup()
	end,
}
