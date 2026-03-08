vim.pack.add({
    { src = "https://github.com/folke/snacks.nvim" },
})
-- Picker
require("snacks").setup({
    notifier = { enabled = true, timeout = 3000 },
    picker = {
        matcher = { frecency = true, cwd_bonus = true, history_bonus = true },
        formatters = { icon_width = 3 },
        win = {
            input = {
                keys = {
                    -- ["<Esc>"] = { "close", mode = { "n", "i" } },
                    ["<C-t>"] = { "edit_tab", mode = { "n", "i" } },
                },
            },
        },
    },
    -- statuscolumn = { enabled = true },
    words = { enabled = true },
    explorer = { enabled = true },
    bigfile = { enabled = true },
    -- terminal = { enabled = true },
    dashboard = {
        enabled = true,
        width = 60,
        row = nil,
        col = nil,
        pane_gap = 4,
        autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", -- autokey sequence
        zindex = 10,
        -- height = 0,
        -- width = 0,
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
        sections = {
            { section = "header" },
            { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
            {
                title = "",
                section = "terminal",
                -- cmd = "echo '         '$NVIM_STARTUP",
                cmd = "echo $NVIM_STARTUP",
                ttl = 3,
                indent = 8,
                gap = 1,
                height = 3,
                padding = 1,
                hl = "footer",
            },
        },
    },
    image = {
        enabled = true,
        doc = { enabled = true, inline = false, float = false, max_width = 80, max_height = 20 },
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
                -- corner_top = "┌",
                -- corner_bottom = "└",
                corner_top = "╭",
                corner_bottom = "╰",
                horizontal = "─",
                vertical = "│",
                arrow = ">",
                -- arrow = "",
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
local map = function(key, func, desc)
    vim.keymap.set({ "n", "v" }, key, func, { desc = desc })
end

map("<leader><space>", Snacks.picker.smart, "Smart find file")
map("<leader>ff", function()
    Snacks.picker.files()
end, "Find nvim config file")

map("<leader>fo", Snacks.picker.recent, "Find recent file")
map("<leader>fg", function()
    Snacks.picker.grep({
        prompt = "Grep> ",
        -- filter = { cwd = true },
    })
end, "Snacks live grep")
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
end, "Find in help")
map("<leader>fl", Snacks.picker.picker_layouts, "Find picker layout")
map("<leader>fk", function()
    Snacks.picker.keymaps({ layout = "dropdown" })
end, "Find keymap")
map("<leader>fb", function()
    Snacks.picker.buffers({ sort_lastused = true })
end, "Find buffers")
map("<leader>fm", Snacks.picker.marks, "Find mark")
map("<leader>fn", function()
    Snacks.picker.notifications({ layout = "dropdown" })
end, "Find notification")
map("grr", Snacks.picker.lsp_references, "Find lsp references")
map("gai", Snacks.picker.lsp_incoming_calls, "C[a]lls Incoming")
map("gao", Snacks.picker.lsp_outgoing_calls, "C[a]lls Outgoing")
map("<leader>fS", Snacks.picker.lsp_workspace_symbols, "Find workspace symbol")
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
            -- on_show = function()
            --   vim.cmd.stopinsert()
            -- end,
        })
    else
        Snacks.picker.treesitter()
    end
end, "Find symbol in current buffer")
-- need network?
map("<leader>fi", Snacks.picker.icons, "Find icon")
map("<leader>fd", Snacks.picker.diagnostics_buffer, "Find diagnostic in current buffer")
map("<leader>fH", Snacks.picker.highlights, "Find highlight")
map("<leader>fc", function()
    Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, "Find nvim config file")
map("<leader>f/", Snacks.picker.search_history, "Find search history")
map("<leader>fj", Snacks.picker.jumps, "Find jump")
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
        Snacks.picker.todo_comments({ keywords = { "NOTE", "TODO", "FIX", "FIXME", "HACK" }, layout = "select" })
    end
end, "Find todo")

map("<leader>fF", function()
    Snacks.picker.lines({ search = "FCN=" })
end, "Find line in current buffer")

-- other snacks features
map("<leader>bc", Snacks.bufdelete.delete, "Delete buffers")
map("<leader>bC", Snacks.bufdelete.other, "Delete other buffers")
-- map("<leader>gg", function()
-- Snacks.lazygit({ cwd = Snacks.git.get_root() })
-- end, "Open lazygit")
map("<leader>n", Snacks.notifier.show_history, "Notification history")
map("<leader>N", Snacks.notifier.hide, "Notification history")
map("<leader>gb", Snacks.git.blame_line, "Git blame line")

map("<leader>K", Snacks.image.hover, "Display image in hover")

map("<leader>z", function()
    Snacks.zen()
end, "Toggle Zen Mode")

map("<leader>Z", function()
    Snacks.zen.zoom()
end, "Toggle Zoom")

map("<leader>e", function()
    Snacks.explorer()
end, "File Explorer")
map("<leader>:", function()
    Snacks.picker.command_history()
end, "Command History")
map("<leader>/", function()
    Snacks.picker.commands()
end, "Commands")
map("<leader>`", ":lua Snacks.terminal()<CR>", "Toggle Terminal")

map("<leader>fC", function()
    Snacks.picker.colorschemes()
end, "Find colorschemes")
map("<leader>fu", function()
    Snacks.picker.undo()
end, "Find undo history")
map("<leader>fq", function()
    Snacks.picker.qflist()
end, "Quickfix List")

vim.keymap.set("n", "<leader>gg", "<cmd>lua Snacks.lazygit()<CR>", { desc = "Open lazygit" })

vim.keymap.set("n", "<leader>n", "<C-\\><C-n>:lua Snacks.terminal.toggle()<CR>", { desc = "打开终端" })
vim.keymap.set("t", "<C-j>", "<C-\\><C-n>:lua Snacks.terminal.open()<CR>", { desc = "打开新终端" })
vim.keymap.set("t", "<C-w>h", "<C-\\><C-n><C-w>h", { desc = "切到前一个终端" })
vim.keymap.set("t", "<C-w>l", "<C-\\><C-n><C-w>l", { desc = "切到后一个终端" })
-- 终端模式快捷键（使用 <C-\><C-n> 退出插入模式后执行命令）
vim.keymap.set("t", "<C-t><C-t>", "<C-\\><C-n>:lua Snacks.terminal.toggle()<CR>", { desc = "打开/隐藏终端" })

-- vim.keymap.set({ 'n', 't' }, '<C-t>', function()
--     Snacks.terminal.toggle()
-- end, { desc = '打开/隐藏终端' })

-- vim.keymap.set('t', '<C-j>', function()
--     Snacks.terminal.open()
--     vim.cmd("startinsert")
--     -- vim.cmd("fish")
-- end, { desc = '打开/隐藏终端' })

-- align to vscode
-- map('<C-S-;>', Snacks.picker.lsp_workspace_symbols, 'Find workspace symbols')
map("<C-S-o>", Snacks.picker.lsp_symbols, "Find workspace symbols")
