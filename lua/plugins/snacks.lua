---@diagnostic disable: undefined-doc-param
vim.pack.add({
    { src = "https://github.com/folke/snacks.nvim" },
})
-- Picker
---@param opts snacks.Config?
require("snacks").setup({
    notifier = { enabled = true, timeout = 3000 },
    picker = {
        matcher = { frecency = true, cwd_bonus = true, history_bonus = true },
        formatters = { icon_width = 3 },
        win = {
            input = {
                keys = {
                    ["<C-t>"] = { "edit_tab", mode = { "n", "i" } },
                },
            },
        },
    },
    words = { enabled = true },
    explorer = { enabled = true },
    bigfile = { enabled = true },
    terminal = { enabled = true },
    dashboard = {
        enabled = true,
        width = 60,
        row = nil,
        col = nil,
        pane_gap = 4,
        autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", -- autokey sequence
        zindex = 10,
        bo = {
            bufhidden = "wipe",
            buftype = "nofile",
            buflisted = false,
            filetype = "snacks_dashboard",
            swapfile = false,
            undofile = false,
        },
        wo = {
            colorcolumn = "",
            cursorcolumn = false,
            cursorline = false,
            foldmethod = "manual",
            list = false,
            number = false,
            relativenumber = false,
            sidescrolloff = 0,
            signcolumn = "no",
            spell = false,
            statuscolumn = "",
            statusline = "",
            winbar = "",
            winhighlight = "Normal:SnacksDashboardNormal,NormalFloat:SnacksDashboardNormal",
            wrap = false,
        },
        preset = {
            keys = {
                { icon = " ", key = "e", desc = "New file", action = ":enew" },
                { icon = " ", key = "f", desc = "Find files", action = ":lua Snacks.picker.smart()" },
                { icon = " ", key = "w", desc = "Find word", action = ":lua Snacks.picker.grep()" },
                { icon = " ", key = "s", desc = "Find sessions", action = ":AutoSession search" },
                { icon = " ", key = "o", desc = "Recent files", action = ":lua Snacks.picker.recent()" },
                {
                    -- find icons to get icon. <leader> f i
                    icon = " ",
                    key = "c",
                    desc = "Config files",
                    action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })",
                },
                { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
                {
                    icon = "󰔛 ",
                    key = "P",
                    desc = "Lazy Profile",
                    action = ":Lazy profile",
                    enabled = package.loaded.lazy ~= nil,
                },
                { icon = " ", key = "M", desc = "Mason", action = ":Mason", enabled = package.loaded.lazy ~= nil },
                { icon = " ", key = "q", desc = "Quit", action = ":qa" },
            },
            header = [[
██╗  ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗
██║  ██║██║██║ ██╔╝██║   ██║██║████╗ ████║
███████║██║█████╔╝ ██║   ██║██║██╔████╔██║
██╔══██║██║██╔═██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║
██║  ██║██║██║  ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
Not a bug, but a feature!
            ]],
        },
        formats = {
            footer = function()
                return { vim.env.NVIM_STARTUP or "", hl = "footer" }
            end,
        },
        sections = {
            { section = "header" },
            { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
            {
                footer = "",
                indent = 8,
                gap = 1,
                height = 3,
                padding = 1,
            },
        },
    },
    image = {
        enabled = true,
        doc = { enabled = true, inline = true, float = false, max_width = 80, max_height = 20 },
    },
    indent = {
        enabled = true,
        indent = { enabled = false },
        animate = { duration = { step = 10, duration = 100 } },
        scope = {
            enabled = false,
            char = "┊",
            underline = true,
            only_current = true,
            hl = {
                "RainbowDelimiterRed",
                "RainbowDelimiterYellow",
                "RainbowDelimiterBlue",
                "RainbowDelimiterOrange",
                "RainbowDelimiterGreen",
                "RainbowDelimiterViolet",
                "RainbowDelimiterCyan",
            },
            priority = 1000,
        },
        chunk = {
            enabled = true,
            char = {
                corner_top = "╭",
                corner_bottom = "╰",
                horizontal = "─",
                vertical = "│",
                arrow = ">",
            },
            only_current = true,
            hl = {
                "RainbowDelimiterRed",
                "RainbowDelimiterYellow",
                "RainbowDelimiterBlue",
                "RainbowDelimiterOrange",
                "RainbowDelimiterGreen",
                "RainbowDelimiterViolet",
                "RainbowDelimiterCyan",
            },
        },
    },
    styles = {
        snacks_image = {
            border = "rounded",
            backdrop = false,
        },
    },
})
local map = function(key, func, opts)
    vim.keymap.set({ "n", "v" }, key, func, opts)
end

map("<leader><space>", Snacks.picker.smart, { desc = "Smart find file" })
map("<leader>ff", Snacks.picker.files, { desc = "Find files" })

map("<leader>fo", Snacks.picker.recent, { desc = "Find recent file" })
map("<leader>fg", function()
    Snacks.picker.grep({
        prompt = "Grep> ",
    })
end, { desc = "Snacks live grep" })
vim.keymap.set({ "n", "v", "x" }, "<leader>fw", function()
    Snacks.picker.grep_word({
        prompt = "| Grep word> ",
        filter = { cwd = true },
        buffers = true,
        dirs = { vim.fn.expand("%:p") }, -- current buffer
    })
end, { desc = "Find word under cursor" })
map("<leader>fh", function()
    Snacks.picker.help({ layout = "dropdown" })
end, { desc = "Find in help" })
map("<leader>fl", Snacks.picker.picker_layouts, { desc = "Find picker layout" })

-- 自定义 keymaps picker 的列排版：修复默认 `format = "keymap"` 的两处问题——
--   1) rhs 列用字节长度(#rhs)补空格、且不截断，长命令会把 desc 顶出右边界，并导致各列不对齐
--   2) desc 之后紧跟 file 列，desc 长短不一时整行错位
-- 列布局：icon | mode | lhs | 定义位置/命令 | desc
-- 其中 lhs 和"定义位置/命令"两列都按实际最大显示宽度动态计算（缓存到 picker 上），
-- 避免固定宽度导致短键/短命令后面空一大段、不够紧凑。

-- 定义位置/命令列的显示文本：
--   * vim 命令映射显示 rhs 命令
--   * Lua 回调（callback）没有 rhs，改显示其定义位置 `文件:行号`，比 "callback" 更有用
local function rhs_text(item)
    local k = item.item
    if k.rhs and k.rhs ~= "" then
        return k.rhs, "SnacksPickerKeymapRhs"
    elseif k.callback then
        if item.file then
            return vim.fn.fnamemodify(item.file, ":t") .. (item.pos and (":" .. item.pos[1]) or ""), "SnacksPickerDir"
        end
        return "callback", "Function"
    end
    return "", "SnacksPickerKeymapRhs"
end

-- 把已解析的 leader 还原成 <leader> 标记（如 " fk" -> "<leader>fk"），
-- 让空格 leader 也能明确显示，而不是一个光秃秃的前导空格。
local function display_lhs(lhs)
    local ml = vim.g.mapleader
    if ml and ml ~= "" and lhs:sub(1, #ml) == ml then
        return "<leader>" .. lhs:sub(#ml + 1)
    end
    return lhs
end

-- 动态计算两列宽度，返回 lhs_w, rhs_w
local function col_width(picker)
    if picker._col_width then
        return picker._col_width[1], picker._col_width[2]
    end
    local items = picker.finder and picker.finder.items
    if not items or #items == 0 then
        return 8, 16 -- 首帧兜底
    end
    local lhs_w, rhs_w = 0, 0
    for _, it in ipairs(items) do
        local km = it.item
        if km then
            lhs_w = math.max(lhs_w, vim.api.nvim_strwidth(display_lhs(km.lhs or "")))
            rhs_w = math.max(rhs_w, vim.api.nvim_strwidth((rhs_text(it))))
        end
    end
    picker._col_width = { math.min(lhs_w, 16), math.min(rhs_w, 18) } -- 封顶，防个别超长键/命令撑爆
    return picker._col_width[1], picker._col_width[2]
end

---@type snacks.picker.format
local function keymap_format(item, picker)
    local a = Snacks.picker.util.align
    local ret = {}
    local k = item.item ---@type vim.api.keyset.get_keymap
    local lhs_w, rhs_w = col_width(picker)

    -- icon（which-key 已加载时显示，否则留空占位，保持列对齐）
    if package.loaded["which-key"] then
        local icon, hl = require("which-key.icons").get({ keymap = k, desc = k.desc })
        if icon then
            ret[#ret + 1] = { a(icon, 3), hl }
        else
            ret[#ret + 1] = { "   " }
        end
    end

    ret[#ret + 1] = { k.mode, "SnacksPickerKeymapMode" }
    ret[#ret + 1] = { " " }
    ret[#ret + 1] = { a(display_lhs(k.lhs), lhs_w, { truncate = true }), "SnacksPickerKeymapLhs" }
    ret[#ret + 1] = { " " }

    local rhs, rhs_hl = rhs_text(item)
    ret[#ret + 1] = { a(rhs, rhs_w, { truncate = true }), rhs_hl }
    ret[#ret + 1] = { " " }

    -- desc：完整显示，不再被截断
    ret[#ret + 1] = { k.desc or "" }
    return ret
end

map("<leader>fk", function()
    Snacks.picker.keymaps({ layout = "dropdown", format = keymap_format })
end, { desc = "Find keymap" })
map("<leader>fb", function()
    Snacks.picker.buffers({ sort_lastused = true })
end, { desc = "Find buffers" })
map("<leader>fm", Snacks.picker.marks, { desc = "Find mark" })
map("<leader>fn", function()
    Snacks.picker.notifications({ layout = "dropdown" })
end, { desc = "Find notification" })
-- LSP
map("gd", Snacks.picker.lsp_definitions, { desc = "Goto Definition" })
map("gD", Snacks.picker.lsp_declarations, { desc = "Goto Declaration" })
map("gr", Snacks.picker.lsp_references, { nowait = true, desc = "References" })
map("<leader>fr", function()
    local get_container = require("utils.treesitter_container").get_container
    local show_container = false
    local picker -- upvalue, assigned below
    local toggle = function()
        if not picker then
            return
        end
        show_container = not show_container
        if show_container then
            -- Lazy-load containers from disk for unopened files
            for _, item in ipairs(picker.finder.items) do
                if item.pos and not item._container then
                    local buf = item.buf
                    if not buf and item.file then
                        local ok, loaded = pcall(vim.fn.bufload, item.file)
                        if ok and loaded and vim.api.nvim_buf_is_loaded(loaded) then
                            buf = loaded
                        end
                    end
                    if buf then
                        item._container = get_container(buf, item.pos[1])
                    end
                end
            end
        end
        picker.list:update({ force = true })
    end
    picker = Snacks.picker.lsp_references({
        transform = function(item)
            -- Only compute for already-loaded buffers (no IO)
            if item.buf and item.pos then
                item._container = get_container(item.buf, item.pos[1])
            end
            return item
        end,
        format = function(item, _)
            if show_container and item._container then
                item.comment = item._container.icon .. item._container.name
            else
                item.comment = nil
            end
            return require("snacks.picker.format").file(item, _)
        end,
        win = {
            input = {
                keys = {
                    ["<C-e>"] = { toggle, mode = { "n", "i" } },
                },
            },
            list = {
                keys = {
                    ["<C-e>"] = { toggle, mode = { "n", "i" } },
                },
            },
        },
    })
end, { desc = "References with container" })
map("gI", Snacks.picker.lsp_implementations, { desc = "Goto Implementation" })
map("gy", Snacks.picker.lsp_type_definitions, { desc = "Goto T[y]pe Definition" })

map("grr", Snacks.picker.lsp_references, { desc = "Find lsp references" })
map("gai", Snacks.picker.lsp_incoming_calls, { desc = "C[a]lls Incoming" })
map("gao", Snacks.picker.lsp_outgoing_calls, { desc = "C[a]lls Outgoing" })
map("<leader>fS", function()
    Snacks.picker.lsp_workspace_symbols({
        on_show = function()
            vim.cmd.stopinsert()
        end,
    })
end, { desc = "Find workspace symbol" })
map("<leader>fs", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })

    local function has_lsp_symbols()
        for _, client in ipairs(clients) do
            if client.server_capabilities.documentSymbolProvider then
                return true
            end
        end
        return false
    end

    if has_lsp_symbols() then
        Snacks.picker.lsp_symbols({
            layout = "dropdown",
            tree = true,
            on_show = function()
                vim.cmd.stopinsert()
            end,
        })
    else
        Snacks.picker.treesitter()
    end
end, { desc = "Find symbol in current buffer" })
map("<leader>fi", Snacks.picker.icons, { desc = "Find icon" })
map("<leader>fd", Snacks.picker.diagnostics_buffer, { desc = "Find diagnostic in current buffer" })
map("<leader>fH", Snacks.picker.highlights, { desc = "Find highlight" })
map("<leader>fc", function()
    Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Find nvim config file" })
map("<leader>f/", Snacks.picker.search_history, { desc = "Find search history" })
map("<leader>fj", Snacks.picker.jumps, { desc = "Find jump" })
map("<leader>ft", function()
    if vim.bo.filetype == "markdown" then
        Snacks.picker.grep_buffers({
            finder = "grep",
            format = "file",
            prompt = " ",
            search = "^\\s*- \\[ \\]",
            regex = true,
            live = false,
            args = { "--no-ignore" },
            on_show = function()
                vim.cmd.stopinsert()
            end,
            buffers = false,
            supports_live = false,
            layout = "ivy",
        })
    else
        Snacks.picker.todo_comments({
            keywords = { "NOTE", "TODO", "FIX", "FIXME", "HACK" },
            layout = "select",
        })
    end
end, { desc = "Find todo" })

map("<leader>fF", Snacks.picker.lines, { desc = "Find line in current buffer" })

-- other snacks features
map("<leader>bc", Snacks.bufdelete.delete, { desc = "Delete buffers" })
map("<leader>bC", Snacks.bufdelete.other, { desc = "Delete other buffers" })
map("<leader>n", Snacks.notifier.show_history, { desc = "Notification history" })
map("<leader>N", Snacks.notifier.hide, { desc = "Hide notification history" })
map("<leader>gb", Snacks.git.blame_line, { desc = "Git blame line" })

map("<leader>K", Snacks.image.hover, { desc = "Display image in hover" })

map("<leader>z", Snacks.zen.zen, { desc = "Toggle Zen Mode" })
map("<leader>Z", Snacks.zen.zoom, { desc = "Toggle Zoom" })
map("<leader>e", Snacks.explorer.open, { desc = "File Explorer" })
map("<leader>:", Snacks.picker.command_history, { desc = "Command History" })
map("<leader>/", Snacks.picker.commands, { desc = "Commands" })

map("<leader>fC", Snacks.picker.colorschemes, { desc = "Find colorschemes" })
map("<leader>fu", Snacks.picker.undo, { desc = "Find undo history" })
map("<leader>fq", Snacks.picker.qflist, { desc = "Quickfix List" })

vim.keymap.set("n", "<leader>gg", "<cmd>lua Snacks.lazygit()<CR>", { desc = "Open lazygit" })
