local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Do things without affecting the registers
keymap.set("n", "x", '"_x')
keymap.set("n", "<Leader>c", '"_c')
keymap.set("n", "<Leader>C", '"_C')
keymap.set("v", "<Leader>c", '"_c')
keymap.set("v", "<Leader>C", '"_C')
keymap.set("n", "<Leader>d", '"_d')
keymap.set("n", "<Leader>D", '"_D')
keymap.set("v", "<Leader>d", '"_d')
keymap.set("v", "<Leader>D", '"_D')

-- Increment/decrement
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")

-- Delete a word backwards
keymap.set("n", "dw", 'vb"_d')


-- Disable continuations
keymap.set("n", "<Leader>o", "o<Esc>^Da", opts)
keymap.set("n", "<Leader>O", "O<Esc>^Da", opts)

-- H move to head of line, L move to end of line
keymap.set("n", "H", "^", opts)
keymap.set("n", "L", "$", opts)

-- New tab
-- keymap.set("n", "te", ":tabedit")
-- keymap.set("n", "<tab>", ":tabnext<Return>", opts)
-- keymap.set("n", "<s-tab>", ":tabprev<Return>", opts)
--

-- 系统剪贴板
keymap.set({ 'n', 'v' }, '<leader>c', '"+y', { desc = 'copy to system clipboard' })
keymap.set({ 'n', 'v' }, '<leader>x', '"+d', { desc = 'cut to system clipboard' })
keymap.set({ 'n', 'v' }, '<leader>p', '"+p', { desc = 'paste to system clipboard' })
-- 窗口切换
keymap.set('n', '<leader>ww', '<C-w>w', { desc = 'focus windows' })
-- 行移动
keymap.set('n', '<A-j>', '<cmd>m .+1<CR>==', { desc = 'Move line down' })
keymap.set('n', '<A-k>', '<cmd>m .-2<CR>==', { desc = 'Move line up' })
keymap.set('v', '<A-j>', "<cmd>m '>+1<CR>gv=gv", { desc = 'Move selection down' })
keymap.set('v', '<A-k>', "<cmd>m '<-2<CR>gv=gv", { desc = 'Move selection up' })
-- 调整窗口大小
keymap.set('n', '<C-Up>', ':resize +2<CR>', { desc = 'Increase window height' })
keymap.set('n', '<C-Down>', ':resize -2<CR>', { desc = 'Decrease window height' })

keymap.set('n', '<leader>w', '<ESC><cmd>write<CR>', { desc = 'save file' })
-- keymap.set('n', '<leader>dd', vim.diagnostic.open_float, { desc = 'diagnostic messages' })

-- LSP 快捷键
keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = 'Go to declaration' })
keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = 'Go to implementation' })
-- keymap.set('n', 'gr', vim.lsp.buf.references, { desc = 'Find references' })
keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename symbol' })
keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'LSP code action' })
