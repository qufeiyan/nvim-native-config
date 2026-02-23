vim.pack.add({
    { src = "https://github.com/rafamadriz/friendly-snippets" },
    { src = "https://github.com/L3MON4D3/LuaSnip" },
})

vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineEnter" }, {
    once = true,
    callback = function()
        require("luasnip.loaders.from_vscode").lazy_load({
            include = {
                "lua",
                "c",
                "cpp",
                "python",
                "rust"
            }
        })

        local luasnip = require("luasnip")

        vim.keymap.set({ "i", "s" }, "<C-j>", function() luasnip.expand_or_jump() end, { silent = true })
        vim.keymap.set({ "i", "s" }, "<C-k>", function() luasnip.jump(-1) end, { silent = true })
        vim.keymap.set({ "i", "s" }, "<C-l>", function()
            if luasnip.choice_active() then
                luasnip.change_choice(1)
            end
        end, { silent = true })
        vim.keymap.set({ "i", "s" }, "<C-h>", function()
            if luasnip.choice_active() then
                luasnip.change_choice(-1)
            end
        end, { silent = true })
    end
})
