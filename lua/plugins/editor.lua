----------------------
-- 插件管理（vim.pack） --
----------------------
vim.pack.add({
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },
    { src = "https://github.com/windwp/nvim-autopairs" }, -- 括号匹配
    { src = "https://github.com/folke/which-key.nvim" },
    -- { src = 'https://github.com/folke/snacks.nvim' },
    { src = "https://github.com/rachartier/tiny-inline-diagnostic.nvim" },
    { src = "https://github.com/MunifTanjim/nui.nvim" },
    { src = "https://github.com/retran/meow.yarn.nvim" },
    { src = "https://github.com/gbprod/yanky.nvim" },
    { src = "https://github.com/folke/flash.nvim" },
    { src = "https://github.com/kylechui/nvim-surround" },
    -- { src = 'https://github.com/akinsho/git-conflict.nvim',  tag = "*" },
    { src = "https://github.com/stevearc/overseer.nvim" },
})

vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        vim.defer_fn(function()
            require("nvim-autopairs").setup()
        end, 1000)
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    once = true,
    callback = function()
        require("tiny-inline-diagnostic").setup({
            -- Choose a preset style for diagnostic appearance
            -- Available: "modern", "classic", "minimal", "powerline", "ghost", "simple", "nonerdfont", "amongus"
            preset = "modern",
            -- Make diagnostic background transparent
            transparent_bg = true,
            -- Make cursorline background transparent for diagnostics
            transparent_cursorline = false,
            signs = {
                vertical = " │",
                vertical_end = " └",
            },
            blend = {
                factor = 0.1,
            },
            options = {
                multilines = {
                    enabled = false, -- Only show messages on one line.
                    always_show = false, -- Always show messages on all lines of multiline diagnostics
                    trim_whitespaces = false, -- Remove leading/trailing whitespace from each line
                    tabstop = 4, -- Number of spaces per tab when expanding tabs
                    severity = nil, -- Filter multiline diagnostics by severity (e.g., { vim.diagnostic.severity.ERROR })
                },
                add_messages = {
                    display_count = false,
                },
                show_source = {
                    enabled = true,
                    if_many = true,
                },
                -- Handle messages that exceed the window width
                overflow = {
                    mode = "wrap", -- "wrap": split into lines, "none": no truncation, "oneline": keep single line
                    padding = 0, -- Extra characters to trigger wrapping earlier
                },
                -- Use icons from vim.diagnostic.config instead of preset icons
                use_icons_from_diagnostic = false,
                -- Color the arrow to match the severity of the first diagnostic
                set_arrow_to_diag_color = true,
                -- Automatically disable diagnostics when opening diagnostic float windows
                override_open_float = false,
                -- Experimental options, subject to misbehave in future NeoVim releases
                experimental = {
                    -- Make diagnostics not mirror across windows containing the same buffer
                    -- See: https://github.com/rachartier/tiny-inline-diagnostic.nvim/issues/127
                    use_window_local_extmarks = false,
                },
            },
        })
        vim.diagnostic.config({
            underline = true,
            virtual_text = false,
            virtual_lines = false,
            update_in_insert = false,
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = "", -- nf-cod-error
                    [vim.diagnostic.severity.WARN] = "", -- nf-cod-warning
                    [vim.diagnostic.severity.INFO] = "", -- nf-cod-info
                    [vim.diagnostic.severity.HINT] = "", -- nf-cod-lightbulb
                },
            },
        })
        -- vim.diagnostic.open_float = require("tiny-inline-diagnostic.override").open_float

        vim.keymap.set("n", "<leader>de", "<cmd>TinyInlineDiag enable<cr>", { desc = "Enable diagnostics" })
        vim.keymap.set("n", "<leader>dd", "<cmd>TinyInlineDiag disable<cr>", { desc = "Disable diagnostics" })
        vim.keymap.set("n", "<leader>dt", "<cmd>TinyInlineDiag toggle<cr>", { desc = "Toggle diagnostics" })
    end,
})

vim.api.nvim_create_autocmd("LspProgress", {
    once = true,
    callback = function()
        vim.defer_fn(function()
            require("meow.yarn").setup({})

            -- Using lua functions
            vim.keymap.set("n", "<leader>yt", function()
                require("meow.yarn").open_tree("type_hierarchy", "supertypes")
            end, { desc = "Yarn: Type Hierarchy (Super)" })
            vim.keymap.set("n", "<leader>yT", function()
                require("meow.yarn").open_tree("type_hierarchy", "subtypes")
            end, { desc = "Yarn: Type Hierarchy (Sub)" })
            vim.keymap.set("n", "<leader>yc", function()
                require("meow.yarn").open_tree("call_hierarchy", "callers")
            end, { desc = "Yarn: Call Hierarchy (Callers)" })
            vim.keymap.set("n", "<leader>yC", function()
                require("meow.yarn").open_tree("call_hierarchy", "callees")
            end, { desc = "Yarn: Call Hierarchy (Callees)" })
        end, 500)
    end,
})

-- custom paste function
local function paste_from_unnamed()
    local lines = vim.split(vim.fn.getreg(""), "\n", { plain = true })
    if #lines == 0 then
        lines = { "" }
    end

    local rtype = vim.fn.getregtype("").sub(1, 1)
    return { lines, rtype }
end

-- vim.opt.clipboard = 'unnamedplus'
vim.g.clipboard = {
    name = "OSC 52",
    copy = {
        ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
        ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
        ["+"] = paste_from_unnamed,
        ["*"] = paste_from_unnamed,
        -- ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
        -- ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
    },
}

vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        local ev = vim.v.event
        if ev.operator == "y" and ev.regname == "" then
            vim.fn.setreg("+", ev.regcontents, ev.regtype)
        end
    end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
    once = true,
    callback = function()
        require("yanky").setup({
            ring = {
                history_length = 100,
                storage = "shada",
                sync_with_numbered_registers = true,
                cancel_event = "update",
                ignore_registers = { "_" },
                update_register_on_cycle = false,
                permanent_wrapper = nil,
            },
            system_clipboard = {
                sync_with_ring = true,
            },
            highlight = {
                on_put = true,
                on_yank = true,
                timer = 500,
            },
        })
    end,

    --- @diagnostic disable-next-line:undefined-field
    vim.keymap.set("n", "<leader>p", function()
        Snacks.picker.yanky()
    end, { desc = "Open Yank History" }),
})

-- 加载终端管理模块
require("config.terminal").setup()

vim.api.nvim_create_autocmd("BufReadPost", {
    once = true,
    callback = function()
        vim.api.nvim_set_hl(0, "FlashBackdrop", {
            fg = "#928374",
        })
        require("flash").setup({
            options = {
                jump = {
                    -- automatically jump when there is only one match.
                    autojump = true,
                },
                label = {
                    uppercase = false,
                },
                highlight = {
                    -- show a backdrop with hl FlashBackdrop
                    backdrop = true,
                    -- Highlight the search matches
                    matches = true,
                    -- extmark priority
                    priority = 5000,
                    groups = {
                        match = "FlashMatch",
                        current = "FlashCurrent",
                        backdrop = "FlashBackdrop",
                        label = "FlashLabel",
                    },
                },
            },
        })
    end,
    vim.keymap.set({ "n", "x", "o" }, "s", function()
        require("flash").jump({
            search = {
                mode = "exact", -- 精确搜索：必须连续匹配
                multi_window = false,
            },
            label = {
                rainbow = { enabled = true },
            },
        })
    end, { desc = "Flash" }),
    vim.keymap.set({ "n", "x", "o" }, "S", function()
        require("flash").treesitter()
    end, { desc = "Flash Treesitter" }),
    vim.keymap.set("o", "r", function()
        require("flash").remote()
    end, { desc = "Remote Flash" }),
    vim.keymap.set({ "o", "x" }, "R", function()
        require("flash").treesitter_search()
    end, { desc = "Treesitter Search" }),
    vim.keymap.set({ "c" }, "<c-s>", function()
        require("flash").toggle()
    end, { desc = "Toggle Flash Search" }),
})

vim.api.nvim_create_autocmd("BufReadPost", {
    once = true,
    callback = function()
        require("overseer").setup({})

        -- keymaps
        vim.keymap.set({ "n", "v" }, "<Leader>rl", "<cmd>OverseerRun<cr>", { desc = "Overseer run templates" })
        local toggle_overseer = function()
            vim.cmd("OverseerToggle")
            -- custom_utils.func_on_window('dapui_stacks', function()
            --     require('dapui').open { reset = true }
            -- end)
        end
        vim.keymap.set("n", "<Leader>ro", toggle_overseer, { desc = "Overseer toggle task list" })
        vim.keymap.set("n", "<C-\\>", toggle_overseer, { desc = "Overseer toggle task list" })
        vim.keymap.set("n", "<Leader>ra", "<cmd>OverseerQuickAction<cr>", { desc = "Overseer quick action list" })
    end,
})

-- autocmds
vim.api.nvim_create_autocmd("FileType", {
    pattern = "OverseerList",
    callback = function()
        vim.opt_local.winfixbuf = true
    end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
    once = true,
    callback = function()
        require("nvim-surround").setup({})
    end,
})

vim.pack.add({
    { src = "https://github.com/folke/todo-comments.nvim" },
})

vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
    group = vim.api.nvim_create_augroup("SetupTodoComments", { clear = true }),
    once = true,
    callback = function()
        require("todo-comments").setup({
            signs = false,
        })
        vim.keymap.set("n", "]t", function()
            require("todo-comments").jump_next({ keywords = { "TODO", "FIXME", "HACK" } })
        end, { desc = "Next todo comment" })

        vim.keymap.set("n", "[t", function()
            require("todo-comments").jump_prev({ keywords = { "TODO", "FIXME", "HACK" } })
        end, { desc = "Previous todo comment" })
    end,
})

local wk = require("which-key")
wk.setup({
    preset = "helix",
    -- preset = "modern"
    -- preset = "classic"
})
wk.add({
    { "<leader>f", group = "file" }, -- group
    { "<leader>l", group = "lsp" }, -- group
    { "<leader>s", group = "auto session" }, -- group
    { "<leader>a", group = "avante" }, -- group
    { "<leader>r", group = "overseer" }, -- group
    { "<leader>g", group = "git" }, -- group
    -- { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File", mode = "n" },
    -- { "<leader>f1", hidden = true },                   -- hide this keymap
    -- { "<leader>w",  proxy = "<c-w>",               group = "windows" },   -- proxy to window mappings
    {
        "<leader>b",
        group = "buffers",
        expand = function()
            return require("which-key.extras").expand.buf()
        end,
    },
    {
        -- Nested mappings are allowed and can be added in any order
        -- Most attributes can be inherited or overridden on any level
        -- There's no limit to the depth of nesting
        mode = { "n", "v" }, -- NORMAL and VISUAL mode
        { "<leader>q", "<cmd>q<cr>", desc = "Quit" }, -- no need to specify mode since it's inherited
        { "<leader>w", "<cmd>w<cr>", desc = "Write" },
    },
})
