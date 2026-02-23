vim.g.mapleader = ' '                           -- 设置 leader 键为空格
vim.opt.number = true                           -- 显示行号
vim.opt.relativenumber = true                   -- 显示相对行号
vim.opt.cursorline = true                       -- 高亮光标所在行
vim.opt.expandtab = true                        -- 使用空格代替 Tab
vim.opt.tabstop = 4                             -- Tab 键宽度为 2
vim.opt.shiftwidth = 4                          -- 缩进宽度为 2
vim.opt.scrolloff = 5                           -- 上下保留 5 行作为缓冲
vim.opt.signcolumn = 'yes'                      -- 永远显示 sign column（诊断标记）
vim.opt.winborder = 'rounded'                   -- 窗口边框样式
vim.opt.ignorecase = true                       -- 搜索忽略大小写
vim.opt.smartcase = true                        -- 当包含大写字母时，搜索区分大小写
vim.opt.hlsearch = true                         -- 搜索匹配不高亮
vim.opt.incsearch = true                        -- 增量搜索
vim.opt.swapfile = false                        -- 关闭vim swapfile
vim.opt.foldcolumn = "1"
vim.opt.foldmethod = 'expr'                     -- 折叠方式使用表达式
vim.opt.foldexpr = 'nvim_treesitter#foldexpr()' -- 使用 Treesitter 表达式折叠
vim.opt.foldlevel = 99                          -- 打开文件时默认不折叠
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
vim.opt.fillchars = 'eob: ,fold: ,foldopen:,foldsep: ,foldinner: ,foldclose:' -- use Neovim nightly branch
---@diagnostic disable-next-line: undefined-field
vim.opt.fillchars:append {
    horiz = "═",
    vert = "║",
    horizup = "╩",
    horizdown = "╦",
    vertleft = "╣",
    vertright = "╠",
    verthoriz = "╬",
}

vim.opt.showcmd = true -- 显示操作命令
vim.opt.title = true
vim.opt.autoindent = true
vim.opt.smartindent = true

vim.opt.wrap = true         -- Display long lines as multiple lines
vim.opt.linebreak = true    -- Wrap at word boundaries, not mid-word
vim.opt.textwidth = 120     -- Insert hard line breaks after 120 chars
vim.opt.colorcolumn = "121" -- Show a vertical guide at 121 characters

vim.opt.backupskip = { "/tmp/*", "/private/tmp/*" }
vim.opt.inccommand = "split"
vim.opt.smarttab = true
vim.opt.breakindent = true
vim.opt.backspace = { "start", "eol", "indent" }
vim.opt.path:append({ "**" }) -- Finding files - Search down into subfolders
vim.opt.wildignore:append({ "*/node_modules/*" })
vim.opt.splitbelow = true     -- Put new windows below current
vim.opt.splitright = true     -- Put new windows right of current
vim.opt.splitkeep = "cursor"

vim.opt.jumpoptions = "stack"

vim.opt.mouse = "a"

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.termguicolors = true
-- Undercurl
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])

-- Add asterisks in block comments
vim.opt.formatoptions:append({ "r" })

-- 使能项目内配置文件 .nvim.lua
vim.opt.exrc = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
-- 设置 listchars
vim.opt.listchars = {
    tab = "→ ",
    trail = "·",
    extends = "›",
    precedes = "‹",
    nbsp = "␣",
}

vim.opt.updatetime = 500 -- Lower than default (4000) to quickly trigger CursorHold
vim.opt.timeoutlen = 300 -- Lower than default (1000) to quickly trigger which-key
vim.opt.laststatus = 3   -- 启用全局状态栏
-- vim.opt.splitkeep = "screen"

vim.opt.undofile = true                              -- 开启持久化撤销
vim.opt.undodir = vim.fn.stdpath('state') .. '/undo' -- 设置撤销文件的存放目录
