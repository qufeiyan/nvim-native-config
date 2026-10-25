vim.pack.add({
    { src = "https://github.com/folke/which-key.nvim" },
})

local wk = require("which-key")
wk.setup({
    preset = "helix",
    -- preset = "modern"
    -- preset = "classic"
    replace = {
        ["<space>"] = "SPC",
        ["<leader>"] = "SPC",
        ["<CR>"] = "RET",
        ["<TAB>"] = "TAB",
        ["<BS>"] = "BS",
        ["<ESC>"] = "ESC",
    },
    icons = {
        breadcrumb = "»",
        separator = "→",
        group = "",
        -- Icons are resolved from `rules` by matching a Lua pattern against the
        -- LOWERCASED description of a mapping. Rules are tested in order and the
        -- first match wins, so keep the specific ones above the generic ones.
        -- Leaf keys fall back to their group's icon when nothing matches.
        rules = {
            -- ── AI / Sidekick ───────────────────────────────────────────
            { pattern = "next edit", icon = "󰓽 ", color = "purple" },
            { pattern = "send", icon = "󰈪 ", color = "purple" },
            { pattern = "sidekick.*cli", icon = "󰊦 ", color = "purple" },
            { pattern = "sidekick", icon = " ", color = "purple" },
            { pattern = "luasnip", icon = "󰃖 ", color = "purple" },
            { pattern = "snippet", icon = "󰃖 ", color = "purple" },

            -- ── Git ─────────────────────────────────────────────────────
            { pattern = "hunk", icon = "󰓩 ", color = "green" },
            { pattern = "stage", icon = "󰆓 ", color = "green" },
            { pattern = "blame", icon = "󰈈 ", color = "green" },
            { pattern = "diff", icon = "󰈕 ", color = "green" },
            { pattern = "conflict", icon = " ", color = "red" },
            { pattern = "choose", icon = "󰆏 ", color = "orange" },
            { pattern = "theirs", icon = "󰓽 ", color = "green" },
            { pattern = "lazygit", icon = "󰊢 ", color = "green" },
            { pattern = "qflist", icon = "󰐥 ", color = "cyan" },
            { pattern = "git", icon = "󰊢 ", color = "green" },

            -- ── Terminal ────────────────────────────────────────────────
            { pattern = "terminal", icon = " ", color = "red" },

            -- ── Session ─────────────────────────────────────────────────
            { pattern = "session", icon = " ", color = "azure" },

            -- ── Diagnostics（必须在 buffer 之前，否则 [d/]d 会误配 buffer 图标）──
            { pattern = "diagnostic", icon = "󱖫 ", color = "green" },

            -- ── Buffers / 列表 / help ───────────────────────────────────
            { pattern = "buffer", icon = "󰈔", color = "cyan" },
            { pattern = "^:b", icon = "󰈔", color = "cyan" },
            { pattern = "^:c", icon = "󰜏 ", color = "cyan" },
            { pattern = "^:l", icon = "󰜏 ", color = "cyan" },
            { pattern = "^:t[nplr]", icon = "󰓹 ", color = "cyan" },
            { pattern = "^:pt", icon = "󰓹 ", color = "cyan" },
            { pattern = "^:n", icon = "󰁔 ", color = "grey" },
            { pattern = "^:p", icon = "󰁍 ", color = "grey" },
            { pattern = "^:r", icon = "󰁍 ", color = "grey" },
            { pattern = "^:help", icon = "󰋖 ", color = "blue" },
            { pattern = "registers", icon = "󰅇 ", color = "yellow" },

            -- ── Notifications ───────────────────────────────────────────
            { pattern = "notif", icon = "󰎟 ", color = "blue" },

            -- ── Todo ────────────────────────────────────────────────────
            { pattern = "todo", icon = " ", color = "orange" },

            -- ── Undo ────────────────────────────────────────────────────
            { pattern = "undo", icon = "󰕍 ", color = "grey" },

            -- ── Treesitter / text-objects ───────────────────────────────
            { pattern = "treesitter", icon = "󰔩 ", color = "yellow" },
            { pattern = "block", icon = "󰑘 ", color = "yellow" },
            { pattern = "scope", icon = "󰑘 ", color = "yellow" },
            { pattern = "function", icon = "󰊕 ", color = "yellow" },
            { pattern = "method", icon = "󰆧 ", color = "yellow" },
            { pattern = "class", icon = "󰂹 ", color = "yellow" },
            { pattern = "node", icon = "󰑘 ", color = "yellow" },
            { pattern = "comment", icon = "󰆈 ", color = "yellow" },
            { pattern = "string", icon = "󰉿 ", color = "yellow" },
            { pattern = "paragraph", icon = "󰦨 ", color = "yellow" },
            { pattern = "sentence", icon = "󰦨 ", color = "yellow" },
            { pattern = "around", icon = "󰑘 ", color = "yellow" },
            { pattern = "^inner", icon = "󰑘 ", color = "yellow" },
            { pattern = "inside", icon = "󰑘 ", color = "yellow" },

            -- ── Explorer ────────────────────────────────────────────────
            { pattern = "explorer", icon = "󰱽 ", color = "yellow" },
            { pattern = "minifile", icon = "󱏒 ", color = "yellow" },
            { pattern = "opened file", icon = " ", color = "yellow" },

            -- ── Folds / 滚动 / 拼写 ─────────────────────────────────────
            { pattern = "fold", icon = " ", color = "cyan" },
            { pattern = "spell", icon = "󰓆 ", color = "cyan" },
            { pattern = "half screen", icon = "󰕵 ", color = "cyan" },
            { pattern = "center this line", icon = "󰕵 ", color = "cyan" },
            { pattern = "top this line", icon = "󰁞 ", color = "cyan" },
            { pattern = "bottom this line", icon = "󰁆 ", color = "cyan" },
            { pattern = "this line", icon = "󰕵 ", color = "cyan" },
            { pattern = "cursor line", icon = "󰕵 ", color = "cyan" },

            -- ── Yank ────────────────────────────────────────────────────
            { pattern = "yank", icon = "󰅌 ", color = "yellow" },

            -- ── Zen / Zoom ──────────────────────────────────────────────
            { pattern = "zen", icon = "󰒑 ", color = "green" },
            { pattern = "zoom", icon = " ", color = "blue" },

            -- ── Images ──────────────────────────────────────────────────
            { pattern = "image", icon = "󰋩 ", color = "purple" },

            -- ── Windows / splits（split/close/quit/swap 必须在 window 之前）──
            { pattern = "height", icon = "󰭌 ", color = "blue" },
            { pattern = "width", icon = "󰭌 ", color = "blue" },
            { pattern = "equally", icon = "󰭌 ", color = "blue" },
            { pattern = "resize", icon = "󰭌 ", color = "blue" },
            -- <C-w> 方向 / 窗口操作（必须在 split / window 之前）
            { pattern = "split window vertically", icon = " ", color = "blue" },
            { pattern = "split window", icon = " ", color = "blue" },
            { pattern = "^left$", icon = " ", color = "blue" },
            { pattern = "^right$", icon = " ", color = "blue" },
            { pattern = "^up$", icon = " ", color = "blue" },
            { pattern = "^down$", icon = " ", color = "blue" },
            { pattern = "far left", icon = " ", color = "blue" },
            { pattern = "far right", icon = " ", color = "blue" },
            { pattern = "far top", icon = " ", color = "blue" },
            { pattern = "far bottom", icon = " ", color = "blue" },
            { pattern = "left window", icon = " ", color = "blue" },
            { pattern = "right window", icon = " ", color = "blue" },
            { pattern = "up window", icon = " ", color = "blue" },
            { pattern = "down window", icon = " ", color = "blue" },
            { pattern = "^top window", icon = " ", color = "blue" },
            { pattern = "^bottom window", icon = " ", color = "blue" },
            { pattern = "new window", icon = " ", color = "green" },
            { pattern = "previous window", icon = " ", color = "blue" },
            { pattern = "switch windows", icon = " ", color = "blue" },
            { pattern = "break out", icon = " ", color = "green" },
            { pattern = "split", icon = "󰃻 ", color = "blue" },
            { pattern = "close", icon = "󰅖 ", color = "red" },
            { pattern = "quit", icon = "󰈆 ", color = "red" },
            { pattern = "swap", icon = "󰓡 ", color = "blue" },
            { pattern = "rotate", icon = " ", color = "blue" },
            { pattern = "preview", icon = "󰈈 ", color = "blue" },
            { pattern = "window", icon = " ", color = "blue" },

            -- ── LSP ─────────────────────────────────────────────────────
            { pattern = "rename", icon = "󰑕 ", color = "blue" },
            { pattern = "code[ _]action", icon = "󰌵 ", color = "blue" },
            { pattern = "hover", icon = "󰋖 ", color = "blue" },
            { pattern = "format", icon = "󰉼 ", color = "cyan" },
            { pattern = "declaration", icon = "󰓩 ", color = "blue" },
            { pattern = "definition", icon = "󰓩 ", color = "blue" },
            { pattern = "implementation", icon = "󰓩 ", color = "blue" },
            { pattern = "hierarchy", icon = "󰑘 ", color = "purple" },
            { pattern = "incoming", icon = " ", color = "purple" },
            { pattern = "outgoing", icon = " ", color = "purple" },
            { pattern = "calls", icon = " ", color = "purple" },
            { pattern = "context", icon = "󰆩 ", color = "blue" },
            { pattern = "inlay", icon = "󰑕 ", color = "blue" },
            { pattern = "references", icon = "󰌹 ", color = "blue" },
            { pattern = "goto", icon = "󰓩 ", color = "blue" },
            { pattern = "codelens", icon = "󰅨 ", color = "orange" },
            { pattern = "lsp", icon = " ", color = "blue" },

            -- ── Marks / winbar ──────────────────────────────────────────
            { pattern = "mark", icon = "󰙒 ", color = "azure" },
            { pattern = "winbar", icon = " ", color = "azure" },

            -- ── Commands ────────────────────────────────────────────────
            { pattern = "command", icon = " ", color = "grey" },
            { pattern = "keymaps", icon = " ", color = "grey" },

            -- ── Find / pickers（放在 word/line 之前，保证 Find xxx 用搜索图标）──
            { pattern = "recent", icon = " ", color = "green" },
            { pattern = "search", icon = " ", color = "green" },
            { pattern = "grep", icon = " ", color = "green" },
            { pattern = "^find", icon = "󰈞 ", color = "green" },
            { pattern = "flash", icon = "󰈸 ", color = "yellow" },

            -- ── 编辑操作符 / motions ─────────────────────────────────────
            { pattern = "run program", icon = "󰆍 ", color = "red" },
            { pattern = "indent", icon = "󰌒 ", color = "grey" },
            { pattern = "matching", icon = "󰜗 ", color = "yellow" },
            { pattern = "ftft", icon = "󰈏 ", color = "grey" },
            { pattern = "cycle", icon = "󰑮 ", color = "grey" },
            { pattern = "black%-hole", icon = "󰊖 ", color = "red" },
            { pattern = "change list", icon = "󰑮 ", color = "grey" },
            { pattern = "change", icon = "󰑮 ", color = "orange" },
            { pattern = "delete", icon = "󰆴 ", color = "red" },
            { pattern = "replace", icon = "󰑕 ", color = "orange" },
            { pattern = "case", icon = "󰀬 ", color = "grey" },
            { pattern = "insert", icon = "󰏫 ", color = "grey" },
            { pattern = "sleep", icon = "󰒲 ", color = "grey" },
            { pattern = "code", icon = "󰅨 ", color = "orange" },
            { pattern = "join", icon = "󰅪 ", color = "grey" },
            { pattern = "write", icon = "󰆓 ", color = "green" },
            { pattern = "new line", icon = "󰑑 ", color = "grey" },
            { pattern = "add empty line", icon = "󰐕 ", color = "grey" },
            { pattern = "number", icon = "󰃬 ", color = "grey" },
            { pattern = "move", icon = "󰕶 ", color = "grey" },
            { pattern = "display", icon = "󰕶 ", color = "grey" },
            { pattern = "visual", icon = "󰈈 ", color = "orange" },
            { pattern = "match", icon = "󰜗 ", color = "yellow" },
            { pattern = "put", icon = "󰆐 ", color = "grey" },
            { pattern = "bracket", icon = "󰜗 ", color = "yellow" },
            { pattern = "^go to end of line", icon = "󰁔 ", color = "grey" },
            { pattern = "^go to first non%-blank", icon = "󰁍 ", color = "grey" },
            { pattern = "word", icon = "󰇊 ", color = "grey" },
            { pattern = "line", icon = "󰁔 ", color = "grey" },
            { pattern = "^next [(<{]", icon = "󰁔 ", color = "grey" },
            { pattern = "^previous [(<{]", icon = "󰁍 ", color = "grey" },

            -- ── 中文描述（misc.lua 等） ──────────────────────────────────

            { pattern = "颜色", icon = " ", color = "cyan" },
            { pattern = "预览", icon = " ", color = "cyan" },
            { pattern = "统计", icon = "󰈈 ", color = "cyan" },
            { pattern = "日志", icon = "󰈕 ", color = "cyan" },
        },
    },
    disable = {
        ft = {
            "snacks_picker_input",
            "snacks_picker_list",
            "snacks_terminal",
            "TelescopePrompt",
            "alpha",
            "dashboard",
            "lazy",
            "mason",
        },
        bt = { "terminal", "prompt" },
    },
})

-- 清除 icon 的下划线样式
vim.api.nvim_set_hl(0, "WhichKeyIcon", { underline = false, default = true })
-- 只保留分组（group）的图标与名字；叶子键的图标由上面的 `rules` 按描述自动匹配
wk.add({
    -- File
    { "<leader>f", group = "file", icon = { icon = "󰈙 ", color = "blue" } },
    { "<leader><space>", icon = { icon = "󰮗 ", color = "green" } },

    -- LSP
    { "<leader>l", group = "lsp", icon = { icon = " ", color = "blue" } },

    -- Git
    { "<leader>g", group = "git", icon = { icon = "󰊢 ", color = "green" } },

    -- Overseer
    { "<leader>r", group = "overseer", icon = { icon = "󰙴 ", color = "orange" } },

    -- Auto session
    { "<leader>s", group = "auto session", icon = { icon = "󰦛 ", color = "azure" } },

    -- AI (sidekick.nvim) — avante 已在 init.lua 中禁用，故 <leader>a 归 sidekick
    { "<leader>a", group = "sidekick", icon = { icon = " ", color = "purple" } },

    -- Terminal
    { "<leader>t", group = "terminal", icon = { icon = " ", color = "red" } },

    -- Buffers
    {
        "<leader>b",
        group = "buffers",
        icon = { icon = "󰈔 ", color = "cyan" },
        expand = function()
            return require("which-key.extras").expand.buf()
        end,
    },

    -- Diagnostics
    { "<leader>d", group = "diagnostics", icon = { icon = "󱖫 ", color = "green" } },

    -- Yarn (type/call hierarchy)
    { "<leader>y", group = "yarn", icon = { icon = "󱞞 ", color = "purple" } },

    -- Explorer
    { "<leader>e", group = "explorer", icon = { icon = "󰱽 ", color = "yellow" } },

    -- Standalone groups
    { "<leader>z", group = "zen", icon = { icon = "󰒑 ", color = "green" } },
    { "<leader>n", group = "notifications", icon = { icon = "󰎟 ", color = "blue" } },

    -- 自动生成的分组（node.desc 为 nil，rules 匹配不到，必须显式给 group + icon）
    { "<leader>", group = "leader", icon = { icon = " ", color = "grey" } },
    { "g", group = "goto", icon = { icon = " ", color = "blue" } },
    { "ga", group = "calls", icon = { icon = " ", color = "purple" } },
    { "z", group = "fold/scroll/spell", icon = { icon = " ", color = "cyan" } },
    { "[", group = "prev", icon = { icon = " ", color = "grey" } },
    { "]", group = "next", icon = { icon = " ", color = "grey" } },

    -- 其他自动生成的分组
    { "<leader>w", group = "swap/focus", icon = { icon = "󰓡 ", color = "blue" } },
    { "<C-W>", group = "window", icon = { icon = " ", color = "blue" } },
    { "gr", group = "references", icon = { icon = "󰌹 ", color = "blue" } },

    -- <C-w> 补全 presets 未覆盖的常用窗口命令（desc 供上面的 rules 出图标）
    {
        mode = { "n", "x" },
        { "<C-w>c", desc = "Close window" },
        { "<C-w>n", desc = "New window" },
        { "<C-w>p", desc = "Previous window" },
        { "<C-w>b", desc = "Move cursor to bottom-right window" },
        { "<C-w>t", desc = "Move cursor to top-left window" },
        { "<C-w>r", desc = "Rotate windows" },
    },
})
