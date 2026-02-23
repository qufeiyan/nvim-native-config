# Neovim 配置

这是我的个人 Neovim 配置文件，基于 **Lua** 编写，旨在提供一个高效、现代化的代码编辑环境。该配置注重性能与可扩展性，集成了常用的插件和自定义优化。

## ✨ 特性

- **快速启动**：使用 neovim 0.12 native 插件管理器，按需加载，启动迅速。
- **全功能 LSP 支持**: 手动安装和管理语言服务器，结合 [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) 实现精准的语法分析、跳转定义、悬停提示等功能。
- **智能补全**：使用 [blink.cmp](https://github.com/saghen/blink.cmp) 提供流畅的代码补全体验，支持 LSP、snippet、buffer、路径等多种来源。
- **代码片段**：集成 [LuaSnip](https://github.com/L3MON4D50/LuaSnip)，支持动态片段扩展，提升编码效率。
- **GitHub Copilot 支持**：集成 [copilot.lua](https://github.com/zbirenbaum/copilot.lua)，通过 `<C-f>` 接受 AI 建议。
- **无缝窗口导航**：通过 [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim) 实现在 Neovim 分屏和终端复用器（如 tmux）之间使用 `Ctrl + h/j/k/l` 自由移动。
- **自定义状态列**：使用 `vim.opt.statuscolumn` 定制左侧信息列，显示行号、折叠标志等。
- **现代化 UI**：配备主题、状态栏、文件树、模糊查找器等插件，提升交互体验。

## 📦 依赖

- Neovim **>= 0.12.0**
- Git（用于插件管理）
- **可选**（根据功能需求）：
  - [npm](https://nodejs.org/)（用于安装某些 LSP 服务器）
  - [rustup](https://rustup.rs/)（用于 rust-analyzer）
  - [ripgrep](https://github.com/BurntSushi/ripgrep)（用于 Telescope 快速搜索）
  - [fd](https://github.com/sharkdp/fd)（文件查找）
  - 终端模拟器（如 WezTerm、kitty）配合终端复用器 （tmux、zellij）使用

## 🚀 安装

1. **备份现有配置**（如果有）：
   ```bash
   mv ~/.config/nvim ~/.config/nvim.bak
   ```

2. **克隆本仓库**：
   ```bash
   git clone https://github.com/qufeiyan/nvim-native-config.git ~/.config/nvim
   ```

3. **启动 Neovim**：
   ```bash
   nvim
   ```
   插件管理器会自动安装所有插件。安装完成后，重启 Neovim 即可使用。

## 🔧 配置结构

```
nvim
├── after
│   └── ftplugin
│       ├── c_cpp.lua
│       ├── lua.lua
│       ├── markdown.lua
│       └── python.lua
├── init.lua
├── lua
│   ├── config
│   │   ├── autocmds.lua
│   │   ├── keymaps.lua
│   │   ├── options.lua
│   │   └── terminal.lua
│   ├── conflict.lua
│   ├── misc.lua
│   ├── plugins
│   │   ├── ai.lua
│   │   ├── avante.lua
│   │   ├── blink.lua
│   │   ├── editor.lua
│   │   ├── lsp.lua
│   │   ├── snacks.lua
│   │   ├── snippet.lua
│   │   ├── treesitter.lua
│   │   └── ui.lua
│   └── stats.lua
├── nvim-pack-lock.json
├── plugin_module_maps.json
└── README.md

6 directories, 24 files
```

## 🎨 自定义

如果你想修改配置：

- **调整选项**：编辑 `lua/config/options.lua`。
- **更改键位**：编辑 `lua/config/keymaps.lua`。
- **增删插件**：在 `lua/plugins/` 目录下添加或删除相应的配置文件，然后重启 Neovim。
- **添加新的 LSP 支持**：默认手动维护语言服务器(已支持clangd)，也可安装 mason 插件，通过 `:Mason` 安装对应的语言服务器，通常无需额外配置，nvim-lspconfig 会自动处理常见语言的设置。如果需要自定义，修改 `lua/plugins/lsp.lua`。

## 📝 注意事项

- **GitHub Copilot** 需要你拥有有效订阅，并在 Neovim 中运行 `:Copilot auth` 完成授权。
- **LSP 服务器**：首次打开支持的文件类型时，mason 会自动提示安装缺失的服务器，或你可以手动运行 `:Mason` 进行安装。
- **补全引擎**：本配置默认使用 **blink.cmp**，若你更喜欢 nvim-cmp，可替换相关配置文件并调整依赖。
- **片段引擎**：默认使用 **LuaSnip**，其片段文件通常存放在 `~/.config/nvim/snippets/` 或通过插件如 `friendly-snippets` 提供。
- 如果你不使用 tmux，smart-splits.nvim 也支持 WezTerm 和 Kitty，请根据终端修改相应配置。
- 部分 LSP 可能需要额外系统依赖（如 Python 的 pyright 需要 npm），请根据 Mason 的提示安装。

## 📄 许可证

[MIT](LICENSE) © [qufeiyan]


