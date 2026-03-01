-- UI
vim.pack.add({
    { src = "https://github.com/olimorris/onedarkpro.nvim" },
    { src = "https://github.com/craftzdog/solarized-osaka.nvim" },
    { src = "https://github.com/morhetz/gruvbox" },           -- 主题
    { src = "https://github.com/nvim-mini/mini.files" },      -- 文件浏览器
    { src = "https://github.com/nvim-mini/mini.statusline" }, -- 状态栏
    { src = "https://github.com/nvim-mini/mini.icons" },
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },
    -- { src = 'https://github.com/akinsho/git-conflict.nvim',     tag = "*" },
})

----------------------
-- 颜色主题 --
----------------------
-- require('solarized-osaka').setup({
--     priority = 1000,
--     options = {
--         transparent = true,
--     }
-- })

-- require("onedarkpro").setup({
--     options = {
--         transparency = true,
--         highlight_inactive_windows = true
--     }
-- })
-- vim.cmd("colorscheme onedark")

vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        require("onedarkpro").setup({
            options = {
                transparency = true,
                highlight_inactive_windows = true,
            },
            highlights = {
                Comment = { italic = true, extend = true },
                Directory = { bold = true },
                ErrorMsg = { italic = true, bold = true },
            },
        })
        -- vim.cmd("colorscheme gruvbox")
        -- vim.cmd("colorscheme solarized-osaka")
        vim.cmd("colorscheme onedark")
    end,
})

local attached_lsp = {}
local copilot = nil
local function statusline_setup()
    local sl = require("mini.statusline")
    sl.setup({
        content = {
            -- Content for active window
            active = function()
                local mode, mode_hl = sl.section_mode({ trunc_width = 120 })
                local git = sl.section_git({ trunc_width = 40 })
                local diff = sl.section_diff({ trunc_width = 75 })
                local diagnostics = sl.section_diagnostics({ trunc_width = 75 })
                -- local lsp = sl.section_lsp({ trunc_width = 75 })
                local filename = sl.section_filename({ trunc_width = 140 })
                local fileinfo = sl.section_fileinfo({ trunc_width = 120 })
                local location = sl.section_location({ trunc_width = 75 })
                local search = sl.section_searchcount({ trunc_width = 75 })

                local compute_attached_lsp = function(buf_id)
                    local names = {}
                    for _, server in pairs(vim.lsp.get_clients({ bufnr = buf_id })) do
                        if server.name == "copilot" then
                            copilot = ""
                        else
                            table.insert(names, server.name)
                        end
                    end

                    local lsps = table.concat(names, ", ")
                    -- vim.notify("lsps:" .. buf_id .. ":" .. lsps)
                    return lsps
                end
                vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
                    pattern = "*",
                    callback = function(arg)
                        local fn = vim.schedule_wrap(function(data)
                            attached_lsp[data.buf] = vim.api.nvim_buf_is_valid(data.buf)
                                and compute_attached_lsp(data.buf)
                                or nil
                            vim.cmd("redrawstatus")
                        end)
                        fn(arg)
                        local buf = vim.api.nvim_get_current_buf()
                        -- vim.notify("fnlsp:" .. buf .. ":" .. (attached_lsp[vim.api.nvim_get_current_buf()] or ""))
                    end,
                })

                local section_lsp = function(args)
                    if sl.is_truncated(args.trunc_width) then
                        return ""
                    end

                    local attached = attached_lsp[vim.api.nvim_get_current_buf()] or ""

                    if attached == "" then
                        return ""
                    end

                    return " " .. attached
                end
                local lsp = section_lsp({ trunc_width = 75 })
                vim.api.nvim_set_hl(0, "CopilotInfo", { fg = "#61AfEF" })
                vim.api.nvim_set_hl(0, "AttachedLSPInfo", { italic = true })

                -- Usage of `MiniStatusline.combine_groups()` ensures highlighting and
                -- correct padding with spaces between groups (accounts for 'missing'
                -- sections, etc.)
                return sl.combine_groups({
                    { hl = mode_hl,                 strings = { mode } },
                    { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics } },
                    { hl = "CopilotInfo",           strings = { copilot or "" } },
                    "%<", -- Mark general truncate point
                    { hl = "MiniStatuslineFilename", strings = { filename } },
                    "%=", -- End left alignment
                    { hl = "AttachedLSPInfo",        strings = { lsp } },
                    { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
                    { hl = mode_hl,                  strings = { search, location } },
                })
            end,
            -- Content for inactive window(s)
            inactive = nil,
        },

        -- Whether to use icons by default
        use_icons = true,
    })
end

vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        local minifiles = require("mini.files")
        minifiles.setup({
            use_as_default_explorer = true,
            windows = {
                preview = true, -- 打开预览窗口
            },
        })
        vim.keymap.set("n", "<leader>ee", function()
            minifiles.open()
        end, { desc = "MiniFiles open" })
        vim.keymap.set("n", "<leader>ef", function()
            -- close 内部会检查是否有打开的explorer, 有则关闭
            minifiles.close()
            minifiles.open(vim.api.nvim_buf_get_name(0), false)
            minifiles.reveal_cwd()
        end, { desc = "Toggle into currently opened file" })
        -- require("mini.statusline").setup({})
        statusline_setup()
    end,
})

-- 彩虹缩进线与括号
vim.pack.add({
    { src = "https://github.com/HiPhish/rainbow-delimiters.nvim" },
    { src = "https://github.com/lukas-reineke/indent-blankline.nvim" },
})

vim.api.nvim_create_autocmd({ "BufReadPost", "BUfNewFile" }, {
    once = true,
    callback = function()
        local highlight = {
            "RainbowRed",
            "RainbowYellow",
            "RainbowBlue",
            "RainbowOrange",
            "RainbowGreen",
            "RainbowViolet",
            "RainbowCyan",
        }
        local hooks = require("ibl.hooks")
        -- create the highlight groups in the highlight setup hook, so they are reset
        -- every time the colorscheme changes
        hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
            -- vim.api.nvim_set_hl(0, "RainbowRed", { link = "RainbowDelimiterRed" })
            -- vim.api.nvim_set_hl(0, "RainbowYellow", { link = "RainbowDelimiterYellow" })
            -- vim.api.nvim_set_hl(0, "RainbowBlue", { link = "RainbowDelimiterBlue" })
            -- vim.api.nvim_set_hl(0, "RainbowOrange", { link = "RainbowDelimiterOrange" })
            -- vim.api.nvim_set_hl(0, "RainbowGreen", { link = "RainbowDelimiterGreen" })
            -- vim.api.nvim_set_hl(0, "RainbowViolet", { link = "RainbowDelimiterViolet" })
            -- vim.api.nvim_set_hl(0, "RainbowCyan", { link = "RainbowDelimiterCyan" })

            vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
            vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
            vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
            vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
            vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
            vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
            vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
        end)
        require("rainbow-delimiters.setup").setup({
            strategy = {
                [""] = "rainbow-delimiters.strategy.global",
                vim = "rainbow-delimiters.strategy.local",
            },
            query = {
                [""] = "rainbow-delimiters",
                lua = "rainbow-blocks",
            },
            priority = {
                [""] = 110,
                lua = 210,
            },
            highlight = highlight,
        })

        -- local indent_highlight = {
        --     "CursorColumn",
        --     "Whitespace",
        -- }
        require("ibl").setup({
            indent = {
                -- highlight = highlight,
                -- char = "|"
                char = "┊",
            },
            whitespace = {
                -- highlight = indent_highlight,
                remove_blankline_trail = false,
            },
            scope = {
                -- char = "┊",
                -- char = "|",
                enabled = false,
                highlight = highlight,
                show_start = true,
                show_end = true,
            },
        })

        hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
    end,
})

-- fidget: lsp progress
vim.pack.add({
    { src = "https://github.com/j-hui/fidget.nvim" },
})

vim.api.nvim_create_autocmd("LspAttach", {
    once = true,
    callback = function()
        require("fidget").setup({
            version = "*",
            options = {
                -- Options related to LSP progress subsystem
                progress = {
                    poll_rate = 0.5,             -- How and when to poll for progress messages
                    suppress_on_insert = true,   -- Suppress new messages while in insert mode
                    ignore_done_already = true,  -- Ignore new tasks that are already complete
                    ignore_empty_message = true, -- Ignore new tasks that don't contain a message
                    -- Clear notification group when LSP server detaches
                    clear_on_detach = function(client_id)
                        local client = vim.lsp.get_client_by_id(client_id)
                        return client and client.name or nil
                    end,
                    -- How to get a progress message's notification group key
                    notification_group = function(msg)
                        return msg.lsp_client.name
                    end,
                    ignore = {}, -- List of LSP servers to ignore

                    -- Options related to how LSP progress messages are displayed as notifications
                    display = {
                        render_limit = 16, -- How many LSP messages to show at once
                        done_ttl = 3, -- How long a message should persist after completion
                        done_icon = "✔", -- Icon shown when all LSP progress tasks are complete
                        done_style = "Constant", -- Highlight group for completed LSP tasks
                        progress_ttl = math.huge, -- How long a message should persist when in progress
                        -- Icon shown when LSP progress tasks are in progress
                        progress_icon = { "dots" },
                        -- Highlight group for in-progress LSP tasks
                        progress_style = "WarningMsg",
                        group_style = "Title",   -- Highlight group for group name (LSP server name)
                        icon_style = "Question", -- Highlight group for group icons
                        priority = 30,           -- Ordering priority for LSP notification group
                        skip_history = true,     -- Whether progress notifications should be omitted from history
                        -- How to format a progress message
                        format_message = require("fidget.progress.display").default_format_message,
                        -- How to format a progress annotation
                        format_annote = function(msg)
                            return msg.title
                        end,
                        -- How to format a progress notification group's name
                        format_group_name = function(group)
                            return tostring(group)
                        end,
                        overrides = { -- Override options from the default notification config
                            rust_analyzer = { name = "rust-analyzer" },
                        },
                    },

                    -- Options related to Neovim's built-in LSP client
                    lsp = {
                        progress_ringbuf_size = 0, -- Configure the nvim's LSP progress ring buffer size
                        log_handler = false,       -- Log `$/progress` handler invocations (for debugging)
                    },
                },

                -- Options related to notification subsystem
                notification = {
                    poll_rate = 10,               -- How frequently to update and render notifications
                    filter = vim.log.levels.INFO, -- Minimum notifications level
                    history_size = 128,           -- Number of removed messages to retain in history
                    override_vim_notify = false,  -- Automatically override vim.notify() with Fidget
                    -- How to configure notification groups when instantiated
                    configs = { default = require("fidget.notification").default_config },
                    -- Conditionally redirect notifications to another backend
                    redirect = function(msg, level, opts)
                        if opts and opts.on_open then
                            return require("fidget.integration.nvim-notify").delegate(msg, level, opts)
                        end
                    end,

                    -- Options related to how notifications are rendered as text
                    view = {
                        stack_upwards = true,    -- Display notification items from bottom to top
                        align = "message",       -- Indent messages longer than a single line
                        reflow = false,          -- Reflow (wrap) messages wider than notification window
                        icon_separator = " ",    -- Separator between group name and icon
                        group_separator = "---", -- Separator between notification groups
                        -- Highlight group used for group separator
                        group_separator_hl = "Comment",
                        line_margin = 1, -- Spaces to pad both sides of each non-empty line
                        -- How to render notification messages
                        render_message = function(msg, cnt)
                            return cnt == 1 and msg or string.format("(%dx) %s", cnt, msg)
                        end,
                    },

                    -- Options related to the notification window and buffer
                    window = {
                        normal_hl = "Comment", -- Base highlight group in the notification window
                        winblend = 100,        -- Background color opacity in the notification window
                        border = "none",       -- Border around the notification window
                        zindex = 45,           -- Stacking priority of the notification window
                        max_width = 0,         -- Maximum width of the notification window
                        max_height = 0,        -- Maximum height of the notification window
                        x_padding = 1,         -- Padding from right edge of window boundary
                        y_padding = 0,         -- Padding from bottom edge of window boundary
                        align = "bottom",      -- How to align the notification window
                        relative = "editor",   -- What the notification window position is relative to
                        tabstop = 8,           -- Width of each tab character in the notification window
                        avoid = {},            -- Filetypes the notification window should avoid
                        -- e.g., { "aerial", "NvimTree", "neotest-summary" }
                    },
                },

                -- Options related to integrating with other plugins
                integration = {
                    ["nvim-tree"] = {
                        enable = true, -- Integrate with nvim-tree/nvim-tree.lua (if installed)
                        -- DEPRECATED; use notification.window.avoid = { "NvimTree" }
                    },
                    ["xcodebuild-nvim"] = {
                        enable = true, -- Integrate with wojciech-kulik/xcodebuild.nvim (if installed)
                        -- DEPRECATED; use notification.window.avoid = { "TestExplorer" }
                    },
                },

                -- Options related to logging
                logger = {
                    level = vim.log.levels.WARN, -- Minimum logging level
                    max_size = 10000,            -- Maximum log file size, in KB
                    float_precision = 0.01,      -- Limit the number of decimals displayed for floats
                    -- Where Fidget writes its logs to
                    path = string.format("%s/fidget.nvim.log", vim.fn.stdpath("cache")),
                },
            },
        })
    end,
})

-- fold
vim.pack.add({
    { src = "https://github.com/kevinhwang91/promise-async" },
    { src = "https://github.com/kevinhwang91/nvim-ufo" },
})

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    once = true,
    callback = function()
        vim.opt.foldcolumn = "1" -- '0' is not bad
        vim.opt.foldlevel = 99   -- Using ufo provider need a large value, feel free to decrease the value
        vim.opt.foldlevelstart = 99
        vim.opt.foldenable = true

        local ftMap = {
            vim = "indent",
            python = { "indent" },
            git = "",
        }

        local handler = function(virtText, lnum, endLnum, width, truncate)
            local newVirtText = {}
            local suffix = (" 󰁂 %d "):format(endLnum - lnum)
            local sufWidth = vim.fn.strdisplaywidth(suffix)
            local targetWidth = width - sufWidth
            local curWidth = 0
            for _, chunk in ipairs(virtText) do
                local chunkText = chunk[1]
                local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                if targetWidth > curWidth + chunkWidth then
                    table.insert(newVirtText, chunk)
                else
                    chunkText = truncate(chunkText, targetWidth - curWidth)
                    local hlGroup = chunk[2]
                    table.insert(newVirtText, { chunkText, hlGroup })
                    chunkWidth = vim.fn.strdisplaywidth(chunkText)
                    -- str width returned from truncate() may less than 2nd argument, need padding
                    if curWidth + chunkWidth < targetWidth then
                        suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
                    end
                    break
                end
                curWidth = curWidth + chunkWidth
            end
            table.insert(newVirtText, { suffix, "MoreMsg" })
            return newVirtText
        end

        -- global handler
        -- `handler` is the 2nd parameter of `setFoldVirtTextHandler`,
        -- check out `./lua/ufo.lua` and search `setFoldVirtTextHandler` for detail.
        -- buffer scope handler
        -- will override global handler if it is existed
        -- local bufnr = vim.api.nvim_get_current_buf()
        -- ufo.setFoldVirtTextHandler(bufnr, handler)

        local ufo = require("ufo")
        ufo.setup({
            open_fold_hl_timeout = 150,
            close_fold_kinds_for_ft = {
                default = { "imports", "comment" },
                -- json = { 'array' },
                c = { "comment", "region" },
            },
            close_fold_current_line_for_ft = {
                default = true,
                c = false,
            },
            preview = {
                win_config = {
                    border = { "", "─", "", "", "", "─", "", "" },
                    winhighlight = "Normal:Folded",
                    winblend = 0,
                },
                mappings = {
                    scrollU = "<C-u>",
                    scrollD = "<C-d>",
                    jumpTop = "[",
                    jumpBot = "]",
                },
            },
            ---@diagnostic disable-next-line: unused-local
            provider_selector = function(bufnr, filetype, buftype)
                -- if you prefer treesitter provider rather than lsp,
                return ftMap[filetype] or { "treesitter", "indent" }
                -- return ftMap[filetype]

                -- refer to ./doc/example.lua for detail
            end,
            fold_virt_text_handler = handler,
        })
        vim.keymap.set("n", "zR", ufo.openAllFolds)
        vim.keymap.set("n", "zM", ufo.closeAllFolds)
        vim.keymap.set("n", "zr", ufo.openFoldsExceptKinds)
        vim.keymap.set("n", "zm", ufo.closeFoldsWith) -- closeAllFolds == closeFoldsWith(0)
        vim.keymap.set("n", "zk", function()
            ufo.peekFoldedLinesUnderCursor()
        end, { desc = "Peek fold" })
    end,
})

vim.pack.add({
    { src = "https://github.com/catgoose/nvim-colorizer.lua" },
})

vim.api.nvim_create_autocmd("BufFilePost", {
    once = true,
    callback = function()
        require("colorizer").setup({
            filetypes = { "*" },          -- Filetype options.  Accepts table like `user_default_options`
            buftypes = {},                -- Buftype options.  Accepts table like `user_default_options`
            -- Boolean | List of usercommands to enable.  See User commands section.
            user_commands = true,         -- Enable all or some usercommands
            lazy_load = false,            -- Lazily schedule buffer highlighting setup function
            user_default_options = {
                names = true,             -- "Name" codes like Blue or red.  Added from `vim.api.nvim_get_color_map()`
                names_opts = {            -- options for mutating/filtering names.
                    lowercase = true,     -- name:lower(), highlight `blue` and `red`
                    camelcase = true,     -- name, highlight `Blue` and `Red`
                    uppercase = false,    -- name:upper(), highlight `BLUE` and `RED`
                    strip_digits = false, -- ignore names with digits,
                    -- highlight `blue` and `red`, but not `blue3` and `red4`
                },
                -- Expects a table of color name to #RRGGBB value pairs.  # is optional
                -- Example: { cool = "#107dac", ["notcool"] = "ee9240" }
                -- Set to false to disable, for example when setting filetype options
                names_custom = false,     -- Custom names to be highlighted: table|function|false
                RGB = true,               -- #RGB hex codes
                RGBA = true,              -- #RGBA hex codes
                RRGGBB = true,            -- #RRGGBB hex codes
                RRGGBBAA = false,         -- #RRGGBBAA hex codes
                AARRGGBB = true,          -- 0xAARRGGBB hex codes 0xffff0000
                rgb_fn = false,           -- CSS rgb() and rgba() functions
                hsl_fn = false,           -- CSS hsl() and hsla() functions
                oklch_fn = false,         -- CSS oklch() function
                css = false,              -- Enable all CSS *features*:
                -- names, RGB, RGBA, RRGGBB, RRGGBBAA, AARRGGBB, rgb_fn, hsl_fn, oklch_fn
                css_fn = false,           -- Enable all CSS *functions*: rgb_fn, hsl_fn, oklch_fn
                -- Tailwind colors.  boolean|'normal'|'lsp'|'both'.  True sets to 'normal'
                tailwind = false,         -- Enable tailwind colors
                tailwind_opts = {         -- Options for highlighting tailwind names
                    update_names = false, -- When using tailwind = 'both', update tailwind names from LSP results.  See tailwind section
                },
                -- parsers can contain values used in `user_default_options`
                sass = { enable = false, parsers = { "css" } }, -- Enable sass colors
                xterm = false,                                  -- Enable xterm 256-color codes (#xNN, \e[38;5;NNNm)
                -- Highlighting mode.  'background'|'foreground'|'virtualtext'
                mode = "background",                            -- Set the display mode
                -- Virtualtext character to use
                virtualtext = "■",
                -- Display virtualtext inline with color.  boolean|'before'|'after'.  True sets to 'after'
                virtualtext_inline = false,
                -- Virtualtext highlight mode: 'background'|'foreground'
                virtualtext_mode = "foreground",
                -- update color values even if buffer is not focused
                -- example use: cmp_menu, cmp_docs
                always_update = false,
                -- hooks to invert control of colorizer
                hooks = {
                    -- called before line parsing.  Accepts boolean or function that returns boolean
                    -- see hooks section below
                    disable_line_highlight = false,
                },
            },
        })
    end,
})

vim.pack.add({
    { src = "https://github.com/rmagatti/auto-session" },
})

vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
        require("auto-session").setup({
            options = {
                -- The following are already the default values, no need to provide them if these are already the settings you want.
                session_lens = {
                    picker = "snacks", -- "telescope"|"snacks"|"fzf"|"select"|nil Pickers are detected automatically but you can also manually choose one. Falls back to vim.ui.select
                    mappings = {
                        -- Mode can be a string or a table, e.g. {"i", "n"} for both insert and normal mode
                        delete_session = { "i", "<C-d>" },
                        alternate_session = { "i", "<C-s>" },
                        copy_session = { "i", "<C-y>" },
                    },

                    picker_opts = {
                        -- For Snacks, you can set layout options here, see:
                        -- https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#%EF%B8%8F-layouts
                        --
                        preset = "dropdown",
                        preview = false,
                        layout = {
                            width = 0.4,
                            height = 0.4,
                        },
                    },

                    -- Telescope only: If load_on_setup is false, make sure you use `:AutoSession search` to open the picker as it will initialize everything first
                    load_on_setup = true,
                },
                auto_restore_last_session = true,
                suppressed_dirs = { "~/", "~/Dev", "~/Documents", "~/Desktop", "~/Projects", "~/Downloads", "/" },
            },
        })
        vim.keymap.set("n", "<leader>sr", ":AutoSession search<CR>", { desc = "Session search" })
        vim.keymap.set("n", "<leader>ss", ":AutoSession save<CR>", { desc = "Save Session" })
        vim.keymap.set("n", "<leader>sa", ":AutoSession toggle<CR>", { desc = "Toggle Session" })
    end,
})

vim.pack.add({
    { src = "https://github.com/stevearc/aerial.nvim" },
})

vim.api.nvim_create_autocmd("User", {
    pattern = "TsLoaded",
    once = true,
    callback = function()
        require("aerial").setup({
            -- optionally use on_attach to set keymaps when aerial has attached to a buffer
            on_attach = function(bufnr)
                -- Jump forwards/backwards with '{' and '}'
                vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
                vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
            end,
            show_guides = true, -- 👈 启用缩进引导线（分割线）
            -- Customize the characters used when show_guides = true
            guides = {
                -- When the child item has a sibling below it
                mid_item = "├─",
                -- When the child item is the last in the list
                last_item = "└─",
                -- When there are nested child guides to the right
                nested_top = "│ ",
                -- Raw indentation
                whitespace = "  ",
            },
            -- autojump = true,
        })
        -- You probably also want to set a keymap to toggle aerial
        vim.keymap.set("n", "<leader>o", "<cmd>AerialToggle!<CR>")
    end,
})
