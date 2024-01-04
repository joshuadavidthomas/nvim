vim.filetype.add({
	pattern = {
		[".env*"] = "config",
		["requirements*.txt"] = "config",
	},
})
