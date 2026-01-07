-- ================================================================================================
-- OPTIONS
-- ================================================================================================
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.opt.laststatus = 3
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wrap = false
vim.opt.showmode = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.inccommand = 'split'
vim.opt.scrolloff = 10
vim.opt.mouse = 'a'
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.cursorline = false
vim.opt.colorcolumn = "100"
vim.opt.signcolumn = 'yes'
vim.opt.swapfile = false
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.foldlevelstart = 99
vim.opt.autoread = true
vim.opt.shada = { "'10", "<0", "s10", "h" }
vim.env.PATH = vim.env.HOME .. "/.local/share/mise/shims:" .. vim.env.PATH

-- ================================================================================================
-- KEYMAPS
-- ================================================================================================
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true })
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<C-h>', '<C-w><C-h>')
vim.keymap.set('n', '<C-l>', '<C-w><C-l>')
vim.keymap.set('n', '<C-j>', '<C-w><C-j>')
vim.keymap.set('n', '<C-k>', '<C-w><C-k>')
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>s', ':e #<CR>', { silent = true })
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>S', ':vs #<CR>', { silent = true })

-- ================================================================================================
-- AUTO COMMANDS
-- ================================================================================================
vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('HighlightYank', {}),
    pattern = '*',
    callback = function()
        vim.hl.on_yank({ higroup = 'IncSearch', timeout = 40 })
    end,
})

-- ================================================================================================
-- PLUGINS
-- ================================================================================================
vim.pack.add({
    { src = "https://github.com/Saghen/blink.cmp", version = vim.version.range('*') },
    { src = "https://github.com/gabefiori/kanagawa.nvim", version = "custom" },
    { src = "https://github.com/echasnovski/mini.nvim" },
    { src = "https://github.com/stevearc/oil.nvim" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    { src = "https://github.com/ibhagwan/fzf-lua" }
})

require('blink.cmp').setup({
    keymap = { preset = 'default' },
    completion = { menu = { auto_show = false } },
    sources = { default = { 'lsp', 'path', 'buffer' } },
    cmdline = { enabled = false },
    fuzzy = { implementation = "prefer_rust_with_warning" },
})

require("kanagawa").setup({
    theme = "custom",    
    background = {     
        dark = "custom", 
        light = "lotus"
    },
})

require('mini.pairs').setup()
require('mini.ai').setup()

local fzf = require('fzf-lua')
fzf.setup({
    {'ivy', 'hide'},
    -- files = { previewer = false },
    previewers = {
        builtin = {
            syntax = true,
            treesitter = false
        }
    }
})

require('oil').setup({
    columns = { "permissions", "size", "mtime" },
    view_options = { show_hidden = true },
    keymaps = {
        ["<C-h>"] = false,
        ["<C-l>"] = false,
    },
})

vim.keymap.set("n", "<C-n>", ":Oil<CR>")
vim.keymap.set("n", "<leader>ff", fzf.files)
vim.keymap.set("n", "<leader>fw", fzf.grep_cword)
vim.keymap.set("n", "<leader>fg", fzf.live_grep_native)
vim.keymap.set("v", "<leader>fg", fzf.grep_visual)
vim.keymap.set("n", "<leader>fr", ":FzfLua live_grep_native resume=true<CR>")

vim.cmd.colorscheme("kanagawa")

-- ================================================================================================
-- TREESITTER
-- ================================================================================================
local treesitter = require('nvim-treesitter')
local parsers = treesitter.get_installed()

treesitter.install({
    "bash", "fish",
    "toml", "yaml", "json",
    "vim", "vimdoc",
    "c", "go", "lua", "odin", "zig", "python", "javascript", "typescript"
})

vim.api.nvim_create_autocmd('FileType', {
    pattern = parsers,
    callback = function()
        vim.treesitter.start()
        vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.wo.foldmethod = 'expr'
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})

-- ================================================================================================
-- LSP
-- ================================================================================================
vim.lsp.enable({ "gopls", "ols", "zls", "ts_ls" })

vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
        vim.opt_local.omnifunc = "v:lua.vim.lsp.omnifunc"

        vim.keymap.set("n", "gr", fzf.lsp_references, { buffer = 0 })
        vim.keymap.set("n", "<leader>dd", fzf.diagnostics_workspace, { buffer = 0 })
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = 0 })
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = 0 })
        vim.keymap.set("n", "gT", vim.lsp.buf.type_definition, { buffer = 0 })
        vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = 0 })
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = 0 })
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = 0 })
        vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { buffer = 0 })
        vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, { buffer = 0 })
        vim.keymap.set("n", "<leader>fm", vim.lsp.buf.format, { buffer = 0 })
    end,
})

vim.diagnostic.config { virtual_text = true, virtual_lines = false }
