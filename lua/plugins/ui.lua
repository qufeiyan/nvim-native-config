-- UI
vim.pack.add({
    { src = "https://github.com/olimorris/onedarkpro.nvim" },
    { src = "https://github.com/craftzdog/solarized-osaka.nvim" },
    { src = "https://github.com/ellisonleao/gruvbox.nvim" },
    { src = "https://github.com/nvim-mini/mini.files" }, -- 文件浏览器
    { src = "https://github.com/nvim-mini/mini.icons" },
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },
    { src = "https://github.com/MunifTanjim/nui.nvim" },
    { src = "https://github.com/folke/noice.nvim" },
    -- { src = 'https://github.com/akinsho/git-conflict.nvim',     tag = "*" },
})

----------------------
-- 颜色主题 --
----------------------
-- Default options:
require("gruvbox").setup({
    terminal_colors = true, -- add neovim terminal colors
    undercurl = true,
    underline = true,
    bold = true,
    italic = {
        strings = true,
        emphasis = true,
        comments = true,
        operators = false,
        folds = true,
    },
    strikethrough = true,
    invert_selection = false,
    invert_signs = false,
    invert_tabline = false,
    inverse = true, -- invert background for search, diffs, statuslines and errors
    contrast = "", -- can be "hard", "soft" or empty string
    palette_overrides = {},
    overrides = {
        Pmenu = { link = "Normal" },
    },
    dim_inactive = false,
    transparent_mode = true,
})
vim.cmd("colorscheme gruvbox")

-- require('solarized-osaka').setup({
--     priority = 1000,
--     options = {
--         transparent = true,
--     }
-- })
-- vim.cmd("colorscheme solarized-osaka")
--
-- require("onedarkpro").setup({
--     options = {
--         transparency = true,
--         highlight_inactive_windows = true,
--     },
--     highlights = {
--         Comment = { italic = true, extend = true },
--         Directory = { bold = true },
--         ErrorMsg = { italic = true, bold = true },
--     },
-- })
-- vim.cmd("colorscheme onedark")
--

local function noice_setup()
    require("noice").setup({
        lsp = {
            -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
            override = {
                ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                ["vim.lsp.util.stylize_markdown"] = true,
                -- ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
            },
        },
        -- you can enable a preset for easier configuration
        presets = {
            bottom_search = true, -- use a classic bottom cmdline for search
            command_palette = true, -- position the cmdline and popupmenu together
            long_message_to_split = true, -- long messages will be sent to a split
            inc_rename = false, -- enables an input dialog for inc-rename.nvim
            lsp_doc_border = true, -- add a border to hover docs and signature help
        },
        -- Position the command popup at the center of the screen
        -- See https://github.com/folke/noice.nvim/blob/0cbe3f88d038320bdbda3c4c5c95f43a13c3aa12/lua/noice/types/nui.lua#L6
        -- See https://github.com/folke/noice.nvim/wiki/Configuration-Recipes
        ---@type NoiceConfigViews
        views = {
            cmdline_popup = {
                backend = "popup",
                -- relative = "editor",
                -- zindex = 200,
                position = {
                    row = "45%", -- 40% from top of the screen. This will position it almost at the center.
                    col = "50%",
                },
                size = {
                    width = "auto",
                    height = "auto",
                },
            },
        },
        cmdline = {
            view = "cmdline_popup", -- cmdline_popup, cmdline
            -- view = "cmdline", -- cmdline_popup, cmdline
        },
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
        noice_setup()
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

-- fold
vim.pack.add({
    { src = "https://github.com/kevinhwang91/promise-async" },
    { src = "https://github.com/kevinhwang91/nvim-ufo" },
})

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    once = true,
    callback = function()
        vim.opt.foldcolumn = "1" -- '0' is not bad
        vim.opt.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
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
            filetypes = { "*" }, -- Filetype options.  Accepts table like `user_default_options`
            buftypes = {}, -- Buftype options.  Accepts table like `user_default_options`
            -- Boolean | List of usercommands to enable.  See User commands section.
            user_commands = true, -- Enable all or some usercommands
            lazy_load = false, -- Lazily schedule buffer highlighting setup function
            user_default_options = {
                names = true, -- "Name" codes like Blue or red.  Added from `vim.api.nvim_get_color_map()`
                names_opts = { -- options for mutating/filtering names.
                    lowercase = true, -- name:lower(), highlight `blue` and `red`
                    camelcase = true, -- name, highlight `Blue` and `Red`
                    uppercase = false, -- name:upper(), highlight `BLUE` and `RED`
                    strip_digits = false, -- ignore names with digits,
                    -- highlight `blue` and `red`, but not `blue3` and `red4`
                },
                -- Expects a table of color name to #RRGGBB value pairs.  # is optional
                -- Example: { cool = "#107dac", ["notcool"] = "ee9240" }
                -- Set to false to disable, for example when setting filetype options
                names_custom = false, -- Custom names to be highlighted: table|function|false
                RGB = true, -- #RGB hex codes
                RGBA = true, -- #RGBA hex codes
                RRGGBB = true, -- #RRGGBB hex codes
                RRGGBBAA = false, -- #RRGGBBAA hex codes
                AARRGGBB = true, -- 0xAARRGGBB hex codes 0xffff0000
                rgb_fn = false, -- CSS rgb() and rgba() functions
                hsl_fn = false, -- CSS hsl() and hsla() functions
                oklch_fn = false, -- CSS oklch() function
                css = false, -- Enable all CSS *features*:
                -- names, RGB, RGBA, RRGGBB, RRGGBBAA, AARRGGBB, rgb_fn, hsl_fn, oklch_fn
                css_fn = false, -- Enable all CSS *functions*: rgb_fn, hsl_fn, oklch_fn
                -- Tailwind colors.  boolean|'normal'|'lsp'|'both'.  True sets to 'normal'
                tailwind = false, -- Enable tailwind colors
                tailwind_opts = { -- Options for highlighting tailwind names
                    update_names = false, -- When using tailwind = 'both', update tailwind names from LSP results.  See tailwind section
                },
                -- parsers can contain values used in `user_default_options`
                sass = { enable = false, parsers = { "css" } }, -- Enable sass colors
                xterm = false, -- Enable xterm 256-color codes (#xNN, \e[38;5;NNNm)
                -- Highlighting mode.  'background'|'foreground'|'virtualtext'
                mode = "background", -- Set the display mode
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
