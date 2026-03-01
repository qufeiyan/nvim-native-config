vim.pack.add({
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
    { src = "https://github.com/zbirenbaum/copilot.lua" },
    { src = "https://github.com/olimorris/codecompanion.nvim" },
})

local function copilot_setup()
    ---@diagnostic disable-next-line: redundant-parameter
    require("copilot").setup({
        panel = {
            enabled = true,
            auto_refresh = false,
            keymap = {
                jump_prev = "[[",
                jump_next = "]]",
                accept = "<CR>",
                refresh = "gr",
                open = "<M-CR>",
            },
            layout = {
                position = "bottom", -- | top | left | right | bottom |
                ratio = 0.4,
            },
        },
        suggestion = {
            enabled = true,
            auto_trigger = true,
            hide_during_completion = true,
            debounce = 15,
            trigger_on_accept = true,
            keymap = {
                accept = "<C-f>",
                accept_word = false,
                accept_line = false,
                next = "<M-]>",
                prev = "<M-[>",
                dismiss = "<C-]>",
                toggle_auto_trigger = false,
            },
        },
        nes = {
            enabled = false, -- requires copilot-lsp as a dependency
            auto_trigger = false,
            keymap = {
                accept_and_goto = false,
                accept = false,
                dismiss = false,
            },
        },
        filetypes = {
            makedown = true,
            help = true,
        },
    })
end

vim.api.nvim_create_autocmd("InsertEnter", {
    once = true,
    callback = function()
        copilot_setup()
    end,
})

vim.api.nvim_create_autocmd("BufEnter", {
    once = true,
    callback = function()
        ---@diagnostic disable-next-line: undefined-field
        require("codecompanion").setup({
            opts = {
                log_level = "DEBUG", -- or "TRACE"
                language = "Chinese",
            },

            -- extensions = {
            --     mcphub = {
            --         callback = "mcphub.extensions.codecompanion",
            --         opts = {
            --             show_result_in_chat = true, -- Show mcp tool results in chat
            --             make_vars = true,           -- Convert resources to #variables
            --             make_slash_commands = true, -- Add prompts as /slash commands
            --         },
            --     },
            -- },
            adapters = {
                http = {
                    opts = {
                        -- show_defaults will cause copilot to not work properly
                        -- show_defaults = true,
                        show_model_choices = true,
                        log_level = "DEBUG",
                    },

                    deepseek = function()
                        return require("codecompanion.adapters").extend("openai_compatible", {
                            name = "deepseek",
                            env = {
                                url = "https://api.deepseek.com",
                                api_key = function()
                                    return os.getenv("DS_API_KEY")
                                end,
                            },
                            schema = {
                                model = {
                                    default = "deepseek-chat",
                                },
                            },
                        })
                    end,

                    deepseek_r1 = function()
                        return require("codecompanion.adapters").extend("deepseek", {
                            name = "deepseek-r1",
                            url = "https://api.deepseek.com",
                            env = {
                                api_key = function()
                                    return os.getenv("DS_API_KEY")
                                end,
                            },
                            schema = {
                                model = {
                                    default = "deepseek-reasoner",
                                    choices = {
                                        ["deepseek-reasoner"] = { opts = { can_reason = true } },
                                    },
                                },
                            },
                        })
                    end,
                },
            },

            interactions = {
                -- chat = { adapter = "openrouter_claude" },
                chat = {
                    adapter = "deepseek",
                },
                inline = { adapter = "copilot" },
                cmd = { adapter = "deepseek" },
            },
        })
    end,
})
