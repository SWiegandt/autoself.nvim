local function add_self(params, self_name)
	local ts = vim.treesitter

	---@diagnostic disable-next-line: missing-parameter
	local _, first_param, _ = ts.query.parse("python", "(identifier) @idents"):iter_captures(params)()
	local param_text = first_param and ts.get_node_text(first_param, 0) or ""

	if string.match(param_text, "self") or string.match(param_text, "cls") then
		return
	end

	local start_row, start_col, end_row, end_col = ts.get_node_range(params)
	local parameter_rows = vim.api.nvim_buf_get_text(0, start_row, start_col + 1, end_row, end_col - 1, {})

	if #parameter_rows > 1 then
		table.insert(parameter_rows, 1, self_name .. ",")
	elseif parameter_rows[1] ~= "" then
		parameter_rows = { self_name .. ", " .. parameter_rows[1] }
	else
		parameter_rows = { self_name }
	end

	vim.api.nvim_buf_set_text(0, start_row, start_col + 1, end_row, end_col - 1, parameter_rows)
end

return function()
	local ts = vim.treesitter
	local current_node = ts.get_node()
	local query = ts.query.get("python", "autoself")

	if not current_node or not query then
		return
	end

	local root = current_node:tree():root()

	---@diagnostic disable-next-line: missing-parameter
	for _, matches, _ in query:iter_matches(root) do
		local self_name = "self"
		local params = nil
		local skip = false

		for id, match in ipairs(matches) do
			local capture = query.captures[id]

			if capture == "decor" then
				local decor = ts.get_node_text(match[1], 0)

				if string.match(decor, "classmethod") then
					self_name = "cls"
				elseif string.match(decor, "staticmethod") then
					skip = true
				end
			elseif capture == "params" then
				params = match[1]
			end
		end

		if not skip then
			add_self(params, self_name)
		end
	end
end
