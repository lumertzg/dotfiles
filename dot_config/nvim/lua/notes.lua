local M = {}

local config = {
	directory = vim.fs.normalize("~/Notes"),
}

local function normalize_directory(directory)
	vim.validate("directory", directory, "string")

	if directory == "~" or vim.startswith(directory, "~/") then
		directory = vim.env.HOME .. directory:sub(2)
	elseif not vim.startswith(directory, "/") then
		error("notes directory must be an absolute path or start with ~/", 0)
	end

	return vim.fs.normalize(directory)
end

local function validate_date(date)
	local year, month, day = date:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
	if not year then
		error("note date must use YYYY-MM-DD format", 0)
	end

	year, month, day = tonumber(year), tonumber(month), tonumber(day)
	local days_in_month = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
	if year % 400 == 0 or (year % 4 == 0 and year % 100 ~= 0) then
		days_in_month[2] = 29
	end

	if year == 0 or month < 1 or month > 12 or day < 1 or day > days_in_month[month] then
		error("note date is not a valid calendar date", 0)
	end
end

function M.open(date)
	date = date or os.date("%Y-%m-%d")
	validate_date(date)

	if vim.fn.isdirectory(config.directory) == 0 then
		if vim.uv.fs_stat(config.directory) then
			error("notes directory path exists and is not a directory", 0)
		end
		vim.fn.mkdir(config.directory, "p")
	end

	local path = vim.fs.joinpath(config.directory, date .. ".md")
	local is_new = vim.uv.fs_stat(path) == nil and vim.fn.bufnr(path) == -1
	vim.cmd.edit(vim.fn.fnameescape(path))

	if is_new then
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "# " .. date, "" })
		vim.api.nvim_win_set_cursor(0, { 2, 0 })
	end
end

function M.setup(opts)
	opts = opts or {}
	config.directory = normalize_directory(opts.directory or "~/Notes")

	vim.api.nvim_create_user_command("Notes", function(command)
		M.open(command.args ~= "" and command.args or nil)
	end, {
		desc = "Open a dated Markdown note",
		nargs = "?",
		force = true,
	})
end

return M
