vim.pack.add({
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
    { src = "https://github.com/copilotlsp-nvim/copilot-lsp" },
    { src = "https://github.com/zbirenbaum/copilot.lua" },
    { src = "https://github.com/olimorris/codecompanion.nvim" },
})

local function copilot_lsp_setup()
    vim.g.copilot_nes_debounce = 500
    vim.lsp.enable("copilot_ls")
    vim.keymap.set("n", "<tab>", function()
        local bufnr = vim.api.nvim_get_current_buf()
        local state = vim.b[bufnr].nes_state
        if state then
            -- Try to jump to the start of the suggestion edit.
            -- If already at the start, then apply the pending suggestion and jump to the end of the edit.
            local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
                or (
                    require("copilot-lsp.nes").apply_pending_nes()
                    and require("copilot-lsp.nes").walk_cursor_end_edit()
                )
            return nil
        else
            -- Resolving the terminal's inability to distinguish between `TAB` and `<C-i>` in normal mode
            return "<C-i>"
        end
    end, { desc = "Accept Copilot NES suggestion", expr = true })
    -- Clear copilot suggestion with Esc if visible, otherwise preserve default Esc behavior
    vim.keymap.set("n", "<esc>", function()
        if not require("copilot-lsp.nes").clear() then
            -- fallback to other functionality
        end
    end, { desc = "Clear Copilot suggestion or fallback" })

    require('copilot-lsp').setup({
        nes = {
            move_count_threshold = 3, -- Clear after 3 cursor movements
        }
    })
end

local function copilot_setup()
    copilot_lsp_setup()
    ---@diagnostic disable-next-line: redundant-parameter
    require('copilot').setup({
        panel = {
            enabled = true,
            auto_refresh = false,
            keymap = {
                jump_prev = "[[",
                jump_next = "]]",
                accept = "<CR>",
                refresh = "gr",
                open = "<M-CR>"
            },
            layout = {
                position = "bottom", -- | top | left | right | bottom |
                ratio = 0.4
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
    end
})

vim.api.nvim_create_autocmd("BufEnter", {
    once = true,
    callback = function()
        require("render-markdown").setup({
            file_types = { "markdown", "Avante" },
            ft = {
                "markdown",
                -- "Avante",
                "codecompanion"
            },
        })

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
                                url = "http://lanz.hikvision.com/v3/openai/deepseek-v3",
                                api_key = function()
                                    return os.getenv("DEEPSEEK_API_KEY")
                                end,
                            },
                            schema = {
                                model = {
                                    default = "deepseek-v3",
                                },
                            },
                        })
                    end,

                    deepseek_r1 = function()
                        return require("codecompanion.adapters").extend("deepseek", {
                            name = "deepseek-r1",
                            url = "http://lanz.hikvision.com/v3/openai/deepseek-v3",
                            env = {
                                api_key = function()
                                    return os.getenv("DEEPSEEK_API_KEY")
                                end,
                            },
                            schema = {
                                model = {
                                    default = "deepseek-r1",
                                    choices = {
                                        ["deepseek-r1"] = { opts = { can_reason = true } },
                                    },
                                },
                            },
                        })
                    end,

                    qwen = function()
                        return require("codecompanion.adapters").extend("openai_compatible", {
                            name = "qwen",
                            env = {
                                url = "http://lanz.hikvision.com/v3/openai/model",
                                api_key = function()
                                    return os.getenv("LANZ_API_KEY")
                                end,
                            },
                            schema = {
                                model = {
                                    default = "Qwen3-Coder-480B",
                                },
                            },
                        })
                    end,

                    glm = function()
                        return require("codecompanion.adapters").extend("openai_compatible", {
                            name = "glm4.7",
                            env = {
                                url = "http://lanz.hikvision.com/v3/openai/model",
                                api_key = function()
                                    return os.getenv("LANZ_API_KEY")
                                end,
                                -- chat_url = "/v1/chat/completions",
                                -- api_key = "sk-8bdbc3ab5b1b4d16929db0285d14f556",
                            },
                            schema = {
                                model = {
                                    default = "GLM-4.7",
                                },
                            },
                        })
                    end,

                    -- Qwen2.5-Coder
                    cmp = function()
                        return require("codecompanion.adapters").extend("openai_compatible", {
                            name = "glm4.7",
                            env = {
                                url = "http://lanz.hikvision.com/v3/openai/model",
                                api_key = function()
                                    return os.getenv("LANZ_API_KEY")
                                end,
                                -- chat_url = "/v1/chat/completions",
                                -- api_key = "sk-8bdbc3ab5b1b4d16929db0285d14f556",
                            },
                            schema = {
                                model = {
                                    default = "Qwen2.5-Coder",
                                },
                            },
                        })
                    end,
                },
                -- acp = {
                --     gemini_cli = function()
                --         return require("codecompanion.adapters").extend("gemini_cli", {
                --             commands = {
                --                 flash = {
                --                     "gemini",
                --                     "--experimental-acp",
                --                     "-m",
                --                     "gemini-2.5-flash",
                --                 },
                --                 pro = {
                --                     "gemini",
                --                     "--experimental-acp",
                --                     "-m",
                --                     "gemini-2.5-pro",
                --                 },
                --             },
                --             defaults = {
                --                 auth_method = "gemini-api-key", -- "oauth-personal" | "gemini-api-key" | "vertex-ai"
                --                 -- auth_method = "oauth-personal",
                --                 -- auth_method = "vertex-ai",
                --             },
                --         })
                --     end,
                -- },
            },


            interactions = {
                -- chat = { adapter = "openrouter_claude" },
                chat = { adapter = "qwen" },
                inline = { adapter = "cmp" },
            },

        })
    end
})
