-- avante

vim.pack.add({
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/MunifTanjim/nui.nvim" },
    { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
    { src = "https://github.com/yetone/avante.nvim" },
})

require("render-markdown").setup({
    file_types = { "markdown", "Avante" },
    ft = { "markdown", "Avante", "codecompanion" },
})


vim.api.nvim_create_autocmd("BufReadPost", {
    once = true,
    callback = function()
        require("avante").setup({
            -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
            build = "make", -- if copying prebuilt lib to an offline env, you may need patchelf to set the rpath.
            -- provider = "deepseek",
            provider = "glm47",
            auto_suggestions_provider = "coder",
            providers = {
                deepseek = {
                    __inherited_from = "openai",
                    api_key_name = "DEEPSEEK_API_KEY",
                    endpoint = "http://lanz.hikvision.com/v3/openai/deepseek-v3",
                    model = "deepseek-v3",
                    max_tokens = 4096,
                    disable_tools = true,
                    extra_request_body = {
                        temperature = 0,
                    }
                },

                glm47 = {
                    __inherited_from = "openai",
                    api_key_name = "GLM_API_KEY",
                    endpoint = "http://lanz.hikvision.com/v3/openai/model",
                    model = "GLM-4.7-Think",
                    max_tokens = 20480,
                    disable_tools = false,
                    extra_request_body = {
                        temperature = 0,
                    }
                },

                coder = {
                    __inherited_from = "openai",
                    api_key_name = "GLM_API_KEY",
                    endpoint = "http://lanz.hikvision.com/v3/openai/model",
                    model = "Qwen2.5-Coder",
                    max_tokens = 20480,
                    disable_tools = false,
                    extra_request_body = {
                        temperature = 0,
                    }
                },

            },


            -- it's no needed if you set env variable.
            input = {
                provider = "snacks", -- "native" | "dressing" | "snacks"
                provider_opts = {
                    -- Snacks input configuration
                    title = "Avante Input",
                    icon = "󱚥 ",
                    -- icon = " ",
                    placeholder = "Enter your API key...",
                },
            },

            suggestion = {
                debounce = 600, -- default : 600
                throttle = 400,
            },

            -- 使用两个模型
            dual_boost = {
                enabled = false,
                first_provider = "openai",
                second_provider = "claude",
                prompt =
                "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Do not provide any explanation, just give the response directly. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
                timeout = 60000, -- Timeout in milliseconds
            },

            behavior = {
                auto_suggestions = true,
                auto_suggestions_respect_ignore = true,
                auto_set_highlight_group = true,
                auto_apply_diff_after_generation = false,
                jump_result_buffer_on_finish = false,
                auto_focus_on_diff_view = true,
                auto_approve_tool_permissions = true,
                auto_check_diagnostics = true,
                confirmation_ui_style = "inline_buttons",
            },

            prompt_logger = {                                           -- logs prompts to disk (timestamped, for replay/debugging)
                enabled = true,                                         -- toggle logging entirely
                log_dir = vim.fn.stdpath("cache") .. "/avante_prompts", -- directory where logs are saved
                fortune_cookie_on_success = false,                      -- shows a random fortune after each logged prompt (requires `fortune` installed)
                next_prompt = {
                    normal = "<C-n>",                                   -- load the next (newer) prompt log in normal mode
                    insert = "<C-n>",
                },
                prev_prompt = {
                    normal = "<C-p>", -- load the previous (older) prompt log in normal mode
                    insert = "<C-p>",
                },
            },
            mappings = {
                --- @class AvanteConflictMappings
                diff = {
                    ours = "co",
                    theirs = "ct",
                    all_theirs = "ca",
                    both = "cb",
                    cursor = "cc",
                    next = "]x",
                    prev = "[x",
                },
                suggestion = {
                    accept = "<M-l>",
                    next = "<M-]>",
                    prev = "<M-[>",
                    dismiss = "<C-]>",
                },
                jump = {
                    next = "]]",
                    prev = "[[",
                },
                submit = {
                    normal = "<CR>",
                    insert = "<C-s>",
                },
                cancel = {
                    normal = { "<C-c>", "<Esc>", "q" },
                    insert = { "<C-c>" },
                },
                sidebar = {
                    apply_all = "A",
                    apply_cursor = "a",
                    retry_user_request = "r",
                    edit_user_request = "e",
                    switch_windows = "<Tab>",
                    reverse_switch_windows = "<S-Tab>",
                    remove_file = "d",
                    add_file = "@",
                    close = { "<Esc>", "q" },
                    close_from_input = nil, -- e.g., { normal = "<Esc>", insert = "<C-d>" }
                },
            },
            selection = {
                enabled = true,
                hint_display = "delayed",
            },

            rules = {
                project_dir = '.avante/rules',         -- relative to project root, can also be an absolute path
                global_dir = '~/.config/avante/rules', -- absolute path
            },
        })
    end
})
