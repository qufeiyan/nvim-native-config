vim.pack.add({
    { src = "https://github.com//lewis6991/gitsigns.nvim" },
})

vim.api.nvim_create_autocmd("BufReadPost", {
    once = true,
    callback = function()
        require("gitsigns").setup({
            signs = {
                add = { text = "┃" },
                change = { text = "┃" },
                delete = { text = "_" },
                topdelete = { text = "‾" },
                changedelete = { text = "~" },
                untracked = { text = "┆" },
            },
            signs_staged = {
                add = { text = "┃" },
                change = { text = "┃" },
                delete = { text = "_" },
                topdelete = { text = "‾" },
                changedelete = { text = "~" },
                untracked = { text = "┆" },
            },
            signs_staged_enable = true,
            signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
            numhl = false,     -- Toggle with `:Gitsigns toggle_numhl`
            linehl = false,    -- Toggle with `:Gitsigns toggle_linehl`
            word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
            watch_gitdir = {
                follow_files = true,
            },
            auto_attach = true,
            attach_to_untracked = false,
            current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
                delay = 1000,
                ignore_whitespace = false,
                virt_text_priority = 100,
                use_focus = true,
            },
            current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
            sign_priority = 6,
            update_debounce = 100,
            status_formatter = nil,  -- Use default
            max_file_length = 40000, -- Disable if file is longer than this (in lines)
            preview_config = {
                -- Options passed to nvim_open_win
                style = "minimal",
                relative = "cursor",
                row = 0,
                col = 1,
            },

            on_attach = function(bufnr)
                local gitsigns = require("gitsigns")

                local function map(mode, l, r, opts)
                    opts = opts or {}
                    opts.buffer = bufnr
                    vim.keymap.set(mode, l, r, opts)
                end

                -- Navigation
                map("n", "]c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "]c", bang = true })
                    else
                        gitsigns.nav_hunk("next")
                    end
                end)

                map("n", "[c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "[c", bang = true })
                    else
                        gitsigns.nav_hunk("prev")
                    end
                end)

                -- Actions
                map("n", "<leader>gs", gitsigns.stage_hunk, { desc = "Stage Hunk" })
                map("n", "<leader>gr", gitsigns.reset_hunk, { desc = "Undo Stage Hunk" })

                map("v", "<leader>gs", function()
                    gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, { desc = "Stage Hunk" })

                map("v", "<leader>gr", function()
                    gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, { desc = "Undo Stage Hunk" })

                map("n", "<leader>gS", gitsigns.stage_buffer, { desc = "Stage Buffer" })
                map("n", "<leader>gR", gitsigns.reset_buffer, { desc = "undo Stage Buffer" })
                map("n", "<leader>gp", gitsigns.preview_hunk, { desc = "Preview Buffer" })
                map("n", "<leader>gi", gitsigns.preview_hunk_inline, { desc = "Preview Hunk Inline" })

                map("n", "<leader>gb", function()
                    gitsigns.blame_line({ full = true })
                end, { desc = "Blame Line" })

                map("n", "<leader>gd", gitsigns.diffthis, { desc = "Diff This" })

                map("n", "<leader>gD", function()
                    gitsigns.diffthis("~")
                end, { desc = "Diff This with ~" })

                map("n", "<leader>gQ", function()
                    gitsigns.setqflist("all")
                end, { desc = "Set qflist" })
                map("n", "<leader>gq", gitsigns.setqflist, { desc = "Set qflist" })

                -- Toggles
                map("n", "<leader>gtb", gitsigns.toggle_current_line_blame, { desc = "Toggle Current Line Blame" })
                map("n", "<leader>gtw", gitsigns.toggle_word_diff, { desc = "Toggle word diff" })

                -- Text object
                map({ "o", "x" }, "ih", gitsigns.select_hunk)
            end,
        })
    end,
})
