vim.pack.add({
    { src = "https://github.com/folke/lazydev.nvim" },
})

vim.api.nvim_create_autocmd("FileType", {
    once = true,
    pattern = "lua",
    callback = function()
        require("lazydev").setup({
            runtime = vim.env.VIMRUNTIME --[[@as string]],
            library = {
                -- Library paths can be absolute
                -- "~/projects/my-awesome-lib",
                -- Or relative, which means they will be resolved from the plugin dir.
                -- "lazy.nvim",
                -- See the configuration section for more details
                -- Load luvit types when the `vim.uv` word is found
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
            ---@diagnostic disable-next-line: unused-local
            enabled = function(root_dir)
                return vim.g.lazydev_enabled == nil and true or vim.g.lazydev_enabled
            end,
            -- disable when a .luarc.json file is found
            -- enabled = function(root_dir)
            -- return not vim.uv.fs_stat(root_dir .. "/.luarc.json")
            -- end,
        })
    end,
})
