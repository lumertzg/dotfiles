local M = {}

local namespace = vim.api.nvim_create_namespace("ReferenceSelection")
local highlighted_buf

local function clear_highlight()
	if highlighted_buf and vim.api.nvim_buf_is_valid(highlighted_buf) then
		vim.api.nvim_buf_clear_namespace(highlighted_buf, namespace, 0, -1)
	end
	highlighted_buf = nil
end

local function highlight_item()
	local list = vim.fn.getqflist({ idx = 0, items = 0 })
	local item = list.items[list.idx]
	if not item or item.bufnr == 0 or item.lnum == 0 then
		return
	end

	clear_highlight()
	local start_col = math.max(item.col - 1, 0)
	local end_col = (item.end_col or 0) > item.col and item.end_col or start_col + 1
	vim.api.nvim_buf_set_extmark(item.bufnr, namespace, item.lnum - 1, start_col, {
		end_col = end_col,
		hl_group = "IncSearch",
	})
	highlighted_buf = item.bufnr
end

local function move(direction)
	local list = vim.fn.getqflist({ idx = 0, size = 0 })
	if list.size == 0 then
		return
	end

	if direction == "next" then
		vim.cmd(list.idx == list.size and "cfirst" or "cnext")
	else
		vim.cmd(list.idx == 1 and "clast" or "cprev")
	end
	highlight_item()
	vim.cmd.copen()
end

local function close()
	clear_highlight()
	vim.cmd.cclose()
end

function M.find()
	vim.lsp.buf.references(nil, {
		on_list = function(list)
			vim.fn.setqflist({}, " ", list)
			vim.cmd.cfirst()
			highlight_item()
			vim.cmd("botright copen")
		end,
	})
end

function M.setup()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "qf",
		callback = function(ev)
			vim.keymap.set("n", "<C-n>", function()
				move("next")
			end, { buffer = ev.buf })
			vim.keymap.set("n", "<C-p>", function()
				move("previous")
			end, { buffer = ev.buf })
			vim.keymap.set("n", "<Esc>", close, { buffer = ev.buf })
			vim.keymap.set("n", "q", close, { buffer = ev.buf })
		end,
	})
end

return M
