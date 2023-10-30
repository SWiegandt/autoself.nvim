local M = {}

local default_opts = {
	languages = { "python" },
}

function M.setup(opts)
	opts = opts or {}
	M.opts = vim.tbl_extend("force", default_opts, opts)

	local autoself_group = vim.api.nvim_create_augroup("AutoSelf", { clear = false })

	for _, language in ipairs(M.opts.languages) do
		vim.api.nvim_create_autocmd("Filetype", {
			group = vim.api.nvim_create_augroup("AutoSelfFiletype", { clear = false }),
			pattern = language,
			callback = function(ev)
				vim.api.nvim_clear_autocmds({
					group = autoself_group,
					buffer = ev.bufnr,
				})

				vim.api.nvim_create_autocmd("InsertLeave", {
					group = autoself_group,
					buffer = ev.bufnr,
					callback = function()
						if vim.opt_local.ft:get() ~= language then
							return
						end

						require("autoself." .. language)()
					end,
				})
			end,
		})
	end
end

return M
