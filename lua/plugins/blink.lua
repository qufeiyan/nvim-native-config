vim.pack.add({
    { src = "https://github.com/onsails/lspkind.nvim" },
    { src = "https://github.com/archie-judd/blink-cmp-words" },
    { src = "https://github.com/fang2hou/blink-copilot" },
    { src = "https://github.com/saghen/blink.cmp",           version = "v1.8.0" },
})

vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineEnter" }, {
    group = vim.api.nvim_create_augroup("SetupCompletion", { clear = true }),
    once = true,
    callback = function()
        require('lspkind').init({
            -- defines how annotations are shown
            -- default: symbol
            -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
            mode = 'symbol_text',
            -- default symbol map
            -- can be either 'default' (requires nerd-fonts font) or
            -- 'codicons' for codicon preset (requires vscode-codicons font)
            -- default: 'default'
            preset = 'codicons',
        })
        require("blink.cmp").setup({
            fuzzy = {
                prebuilt_binaries = {
                    download = true,
                },
                implementation = "prefer_rust_with_warning",
                -- implementation = "lua",
            },
            completion = {
                documentation = {
                    auto_show = true,
                    window = {
                        border = "single",
                        scrollbar = false,
                    },
                },
                menu = {
                    border = "single",
                    auto_show = true,
                    auto_show_delay_ms = 0,
                    scrollbar = false,
                    draw = {
                        padding = { 0, 1 }, -- padding only on right side
                        components = {
                            kind_icon = {
                                text = function(ctx)
                                    local icon = ctx.kind_icon
                                    if vim.tbl_contains({ "Path" }, ctx.source_name) then
                                        local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
                                        if dev_icon then
                                            icon = dev_icon
                                        end
                                    elseif icon == "" then
                                        icon = require("lspkind").symbol_map[ctx.kind] or ""
                                    end
                                    -- if ctx.source_name == "copilot" then
                                    --     icon = ""
                                    -- end
                                    return icon .. ctx.icon_gap
                                end,

                                -- Optionally, use the highlight groups from nvim-web-devicons
                                -- You can also add the same function for `kind.highlight` if you want to
                                -- keep the highlight groups in sync with the icons.
                                highlight = function(ctx)
                                    local hl = ctx.kind_hl
                                    if vim.tbl_contains({ "Path" }, ctx.source_name) then
                                        local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
                                        if dev_icon then
                                            hl = dev_hl
                                        end
                                    end
                                    return hl
                                end,
                            }
                        },
                        columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "source_name" } },
                        treesitter = { 'lsp' },
                    },
                },
                ghost_text = {
                    enabled = true,
                    show_with_menu = true,
                }
            },
            keymap = {
                preset = "super-tab",
                -- ["<C-u>"] = { "scroll_documentation_up", "fallback" },
                -- ["<C-d>"] = { "scroll_documentation_down", "fallback" },
                ["<Tab>"] = {
                    function(cmp)
                        if vim.b[vim.api.nvim_get_current_buf()].nes_state then
                            cmp.hide()
                            return (
                                require("copilot-lsp.nes").apply_pending_nes()
                                and require("copilot-lsp.nes").walk_cursor_end_edit()
                            )
                        end
                        if cmp.snippet_active() then
                            return cmp.accept()
                        else
                            return cmp.select_and_accept()
                        end
                    end,
                    "snippet_forward",
                    "fallback",
                },
            },
            signature = {
                enabled = true,
            },
            cmdline = {
                completion = {
                    menu = {
                        auto_show = true,
                        -- border = "none",
                    },
                },
            },
            snippets = { preset = "luasnip" },
            sources = {
                -- Add 'avante' to the list
                default = {
                    -- 'avante',
                    'lsp',
                    'copilot',
                    -- 'codecompanion',
                    'snippets',
                    'path',
                    'buffer',
                    'dictionary',
                },

                providers = {
                    copilot = {
                        name = "copilot",
                        module = "blink-copilot",
                        score_offset = 100,
                        async = true,
                        opts = {
                            -- Local options override global ones
                            max_completions = 3, -- Override global max_completions

                            -- Final settings:
                            -- * max_completions = 3
                            -- * max_attempts = 2
                            -- * all other options are default
                            max_attempts = 4,
                            kind_name = "Copilot", ---@type string | false
                            kind_icon = "", ---@type string | false
                            kind_hl = false, ---@type string | false
                            debounce = 200, ---@type integer | false
                            auto_refresh = {
                                backward = true,
                                forward = true,
                            },
                        }
                    },
                    snippets = {
                        score_offset = 1000,
                        should_show_items = function(ctx) -- avoid triggering snippets after . " ' chars.
                            return ctx.trigger.initial_kind ~= "trigger_character"
                        end,
                    },
                    -- Use the thesaurus source
                    thesaurus = {
                        name = "blink-cmp-words",
                        module = "blink-cmp-words.thesaurus",
                        -- All available options
                        opts = {
                            -- A score offset applied to returned items.
                            -- By default the highest score is 0 (item 1 has a score of -1, item 2 of -2 etc..).
                            score_offset = 0,

                            -- Default pointers define the lexical relations listed under each definition,
                            -- see Pointer Symbols below.
                            -- Default is as below ("antonyms", "similar to" and "also see").
                            definition_pointers = { "!", "&", "^" },

                            -- The pointers that are considered similar words when using the thesaurus,
                            -- see Pointer Symbols below.
                            -- Default is as below ("similar to", "also see" }
                            similarity_pointers = { "&", "^" },

                            -- The depth of similar words to recurse when collecting synonyms. 1 is similar words,
                            -- 2 is similar words of similar words, etc. Increasing this may slow results.
                            similarity_depth = 2,
                        },
                    },

                    -- The default behavior is to only show completions from visible "normal" buffers (e.g. it wouldn't include neo-tree). This will instead show completions from all buffers, even if they're not visible on screen. Note that the performance impact of this has not been tested.
                    buffer = {
                        opts = {
                            -- get all buffers, even ones like neo-tree
                            get_bufnrs = vim.api.nvim_list_bufs
                            -- -- or (recommended) filter to only "normal" buffers
                            -- get_bufnrs = function()
                            --     return vim.tbl_filter(function(bufnr)
                            --         return vim.bo[bufnr].buftype == ''
                            --     end, vim.api.nvim_list_bufs())
                            -- end
                        }
                    },

                    -- Use the dictionary source
                    dictionary = {
                        name = "blink-cmp-words",
                        module = "blink-cmp-words.dictionary",
                        -- All available options
                        opts = {
                            -- The number of characters required to trigger completion.
                            -- Set this higher if completion is slow, 3 is default.
                            dictionary_search_threshold = 3,

                            -- See above
                            score_offset = 0,

                            -- See above
                            definition_pointers = { "!", "&", "^" },
                        },
                    },
                },
                -- Setup completion by filetype
                per_filetype = {
                    text = { "dictionary" },
                    markdown = { "thesaurus" },
                    typst = { "lsp", "snippets", "dictionary" },
                    tex = { "dictionary", "thesaurus" },
                },
            },
        })
    end,
})

