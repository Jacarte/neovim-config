-- General keymaps that are not pluggin dependant
-- the file "lua/lsp/utils.lua" contains lsp-specific commands.

local Utils = require('utils')

-- local exprnnoremap = Utils.exprnnoremap
local nnoremap = Utils.nnoremap
local tnoremap = Utils.tnoremap
local vnoremap = Utils.vnoremap
local nmap = Utils.nmap
local map = Utils.map
-- local xnoremap = Utils.xnoremap
local inoremap = Utils.inoremap
-- local tnoremap = Utils.tnoremap
-- local nmap = Utils.nmap
-- local xmap = Utils.xmap

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- quick edit
nnoremap("<C-z>", ":undo ")


-- kj to normal mode
inoremap("kj", "<Esc>")

-- Run omnifunc, mostly used for autocomplete
inoremap("<C-SPACE>", "<C-x><C-o>")

-- Save with Ctrl + S
nnoremap("<C-s>", ":w<CR>")

-- Close buffer
nnoremap("<C-c>", ":q<CR>")

-- Move around windows (shifted to the right)
nnoremap("<C-h>", "<C-w>h")
nnoremap("<C-j>", "<C-w>j")
nnoremap("<C-k>", "<C-w>k")
nnoremap("<C-l>", "<C-w>l")

-- Switch buffers (needs nvim-bufferline)
nnoremap("<TAB>", ":BufferLineCycleNext<CR>")
map("n", "E", "<CMD>NvimTreeFocus<CR>")
-- Commented out, Shift Tab to focus the file explorer
nnoremap("<S-TAB>", ":BufferLineCyclePrev<CR>")

-- Splits
nnoremap("<leader>ws", ":split<CR>")
nnoremap("<leader>vs", ":vsplit<CR>")

-- Populate substitution
nnoremap("<leader>s", ":s//g<Left><Left>")
nnoremap("<leader>S", ":%s//g<Left><Left>")
nnoremap("<leader><C-s>", ":%s//gc<Left><Left><Left>")

vnoremap("<leader>s", ":s//g<Left><Left>")
vnoremap("<leader><A-s>", ":%s//g<Left><Left>")
vnoremap("<leader>S", ":%s//gc<Left><Left><Left>")

-- Delete buffer
nnoremap("<A-w>", ":bd<CR>")

-- Yank to end of line
nnoremap("Y", "y$")

-- Copy to system clippboard
nnoremap("<leader>y", '"+y')
vnoremap("<leader>y", '"+y')

-- Paste from system clippboard
nnoremap("<leader><C-v>", '"+p')
vnoremap("<leader><C-v>", '"+p')

-- Clear highlight search
nnoremap("<leader>nh", ":nohlsearch<CR>")
vnoremap("<leader>nh", ":nohlsearch<CR>")

-- Local list
nnoremap("<leader>lo", ":lopen<CR>")
nnoremap("<leader>lc", ":lclose<CR>")
nnoremap("<C-n>", ":lnext<CR>")
nnoremap("<C-p>", ":lprev<CR>")

-- Quickfix list
nnoremap("<leader>co", ":copen<CR>")
nnoremap("<leader>cc", ":cclose<CR>")
nnoremap("<C-N>", ":cnext<CR>")
nnoremap("<C-P>", ":cprev<CR>")

-- Open file in default application
nnoremap("<leader>xo", "<Cmd> !xdg-open %<CR><CR>")

-- Fugitive
nnoremap("<leader>G", ":G<CR>")
nnoremap("<leader>gh", ":Gclog<CR>")

-- Show line diagnostics
nnoremap("<leader>d", '<Cmd>lua vim.diagnostic.open_float(0, {scope = "line"})<CR>')

-- Open local diagnostics in local list
nnoremap("<leader>D", "<Cmd>lua vim.diagnostic.setloclist()<CR>")

-- Open all project diagnostics in quickfix list
nnoremap("<leader><A-d>", "<Cmd>lua vim.diagnostic.setqflist()<CR>")

-- Telescope
nnoremap("<leader>ff", "<Cmd>Telescope find_files<CR>")
nnoremap("<leader>fhf","<Cmd>Telescope find_files hidden=true<CR>")
nnoremap("<leader>fb", "<Cmd>Telescope buffers<CR>")
nnoremap("<leader>fg", "<Cmd>Telescope live_grep<CR>")

-- File explorer
nnoremap("<leader>e", "<Cmd>NvimTreeToggle<CR>")  -- NvimTree

-- Lazygit on floatterm
-- It needs lazygit, brew install jesseduffield/lazygit/lazygit
nnoremap("GW", "<Cmd>lua _lazygit_toggle()<CR>")

-- To fix neoterm
--:tnoremap <Esc> <C-\><C-n>
tnoremap("<Esc>", "<C-\\><C-n>")
-- nnoremap("<leader>ft", ":FloatermNew --name=float --height=0.8 --width=0.7 --autoclose=2 zsh <CR>")
-- We replace now by toggle term
-- nnoremap("t", ":FloatermToggle float <CR>")
nnoremap("t", '<Cmd>exe v:count1."ToggleTerm direction=horizontal"<CR>')

-- nnoremap("<leader>e", "<Cmd>RnvimrToggle<CR>")

-- EasyAlign
-- xmap("ga", "<cmd>EasyAlign")
-- nmap("ga", "<cmd>EasyAlign")
--
--
-- vimspector
-- nnoremap("<F9>", "<Cmd>call vimspector#Launch()<CR>")
-- nnoremap("<F5>","<Cmd>VimspectorStepOver<CR>")
-- nnoremap("<F8>", "<Cmd>call vimspector#Reset()<CR>")
-- nnoremap("<F11>", "<Cmd>call vimspector#StepOver()<CR>")
-- nnoremap("<F12>", "<Cmd>call vimspector#StepOut()<CR>")
-- nnoremap("<F10>", "<Cmd>call vimspector#StepInto()<CR>")

-- nnoremap("Db", "<Plug>VimspectorToggleBreakpoint")
-- nnoremap("Dw", ":call vimspector#AddWatch()<CR>")
-- nnoremap("De", ":call vimspector#Evaluate()<CR>")

-- nnoremap("<leader>db", "<Cmd>lua require('plugins.vimspector').generate_debug_profile()<CR>")


-- local exprnnoremap = Utils.exprnnoremap
--
-- dap
nnoremap("Db", "lua require'dapui'.eval()<CR>")
