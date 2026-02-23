--[[
Neovim 配置
1. 本配置使用 Neovim 0.12 内置 API（vim.pack）进行插件管理。
2. 实现了基本的编辑功能、LSP 支持、终端管理等功能。
3. 实现了类似lazyvim 的评估插件加载时间的功能。
--]]

require("stats")
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("plugins.treesitter")
require("plugins.ui")
require("plugins.blink")
-- 加载终端管理模块
require("config.terminal").setup()
require("plugins.lsp")
require("plugins.snacks")
require("plugins.editor")
require("plugins.snippet")
-- require("plugins.avante")
require("plugins.ai")
require("misc")
