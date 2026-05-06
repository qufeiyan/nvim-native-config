vim.pack.add({
    { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-context" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects" },
    { src = "https://github.com/Bekaboo/dropbar.nvim" },
})

vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
    -- vim.api.nvim_create_autocmd({ 'VimEnter' }, {
    group = vim.api.nvim_create_augroup("SetupTreesitter", { clear = true }),
    once = true,
    callback = function()
        -- require("nvim-treesitter").setup({})
        local ensureInstalled = {
            'lua', 'python', 'typescript', 'c', 'cpp', 'rust', 'make', 'snakemake', 'vim', 'vimdoc', 'markdown',
            'markdown_inline',
            -- ... your parsers
        }
        local alreadyInstalled = require('nvim-treesitter.config').get_installed()
        local parsersToInstall = vim.iter(ensureInstalled)
            :filter(function(parser)
                return not vim.tbl_contains(alreadyInstalled, parser)
            end)
            :totable()
        require('nvim-treesitter').install(parsersToInstall)
        require("treesitter-context").setup({
            separator = nil,
            max_lines = 3,
            multiwindow = true,
            min_window_height = 15,
        })
        vim.api.nvim_set_hl(0, "TreesitterContext", { link = "CursorLine" })       -- remove existing link
        vim.api.nvim_set_hl(0, "TreesitterContextBottom", { link = "CursorLine" }) -- remove existing link
        vim.keymap.set("n", "[c", function()
            require("treesitter-context").go_to_context(vim.v.count1)
        end, { silent = true, desc = "go to context" })

        -- Treesitter 配置完成后，触发自定义事件
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.api.nvim_exec_autocmds("User", { pattern = "TsLoaded" })

        -- configuration of textobjects
        require("nvim-treesitter-textobjects").setup({
            select = {
                -- Automatically jump forward to textobj, similar to targets.vim
                lookahead = true,
                -- You can choose the select mode (default is charwise 'v')
                --
                -- Can also be a function which gets passed a table with the keys
                -- * query_string: eg '@function.inner'
                -- * method: eg 'v' or 'o'
                -- and should return the mode ('v', 'V', or '<c-v>') or a table
                -- mapping query_strings to modes.
                selection_modes = {
                    ["@parameter.outer"] = "v", -- charwise
                    ["@function.outer"] = "V",  -- linewise
                    -- ['@class.outer'] = '<c-v>', -- blockwise
                },
                -- If you set this to `true` (default is `false`) then any textobject is
                -- extended to include preceding or succeeding whitespace. Succeeding
                -- whitespace has priority in order to act similarly to eg the built-in
                -- `ap`.
                --
                -- Can also be a function which gets passed a table with the keys
                -- * query_string: eg '@function.inner'
                -- * selection_mode: eg 'v'
                -- and should return true of false
                include_surrounding_whitespace = false,
            },
        })

        -- keymaps
        -- You can use the capture groups defined in `textobjects.scm`
        vim.keymap.set({ "x", "o" }, "am", function()
            require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
        end, { desc = "around method block" })
        vim.keymap.set({ "x", "o" }, "im", function()
            require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
        end, { desc = "inner method block" })
        vim.keymap.set({ "x", "o" }, "ac", function()
            require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
        end, { desc = "around class block" })
        vim.keymap.set({ "x", "o" }, "ic", function()
            require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
        end, { desc = "inner class block" })
        -- You can also use captures from other query groups like `locals.scm`
        vim.keymap.set({ "x", "o" }, "as", function()
            require("nvim-treesitter-textobjects.select").select_textobject("@local.scope", "locals")
        end, { desc = "around local scope block" })

        vim.keymap.set({ "n", "x", "o" }, "]a", function()
            require("nvim-treesitter-textobjects.move").goto_next_start("@parameter.inner", "textobjects")
        end, { desc = "next args(start)" })
        vim.keymap.set({ "n", "x", "o" }, "[a", function()
            require("nvim-treesitter-textobjects.move").goto_previous_start("@parameter.inner", "textobjects")
        end, { desc = "previous args(start)" })

        vim.keymap.set({ "n", "x", "o" }, "]A", function()
            require("nvim-treesitter-textobjects.move").goto_next_end("@parameter.inner", "textobjects")
        end, { desc = "next args(end)" })
        vim.keymap.set({ "n", "x", "o" }, "[A", function()
            require("nvim-treesitter-textobjects.move").goto_previous_end("@parameter.inner", "textobjects")
        end, { desc = "previous args(end)" })
        -- conflict with lsp "]f", use "]m"
        vim.keymap.set({ "n", "x", "o" }, "]f", function()
            require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
        end, { desc = "next function(start)" })
        vim.keymap.set({ "n", "x", "o" }, "]F", function()
            require("nvim-treesitter-textobjects.move").goto_next_end("@function.outer", "textobjects")
        end, { desc = "next function(end)" })
        vim.keymap.set({ "n", "x", "o" }, "[f", function()
            require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
        end, { desc = "previous function(start)" })
        vim.keymap.set({ "n", "x", "o" }, "[F", function()
            require("nvim-treesitter-textobjects.move").goto_previous_end("@function.outer", "textobjects")
        end, { desc = "previous function(end)" })
    end, -- configuration
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp", "python", "make", "rust" },
    callback = function()
        -- Enable treesitter highlighting and disable regex syntax
        pcall(vim.treesitter.start)
        -- Enable treesitter-based indentation
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

        -- Enable treesitter-based folding
        vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.wo[0][0].foldmethod = 'expr'
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    once = true,
    callback = function()
        vim.defer_fn(function()
            require("dropbar").setup({
                icons = {
                    enable = true,
                    kinds = {
                        dir_icon = function(_)
                            return "󰝰 ", "DropBarIconKindFolder"
                        end,
                    },
                },
            })
            local dropbar_api = require("dropbar.api")
            vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
            vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
            vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })

            vim.ui.select = require("dropbar.utils.menu").select
        end, 50)
    end,
})
