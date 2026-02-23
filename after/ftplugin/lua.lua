if vim.b.did_my_ftplugin then
    return
end
vim.b.did_my_ftplugin = true

vim.api.nvim_create_autocmd("BufReadPost", {
    once = true,
    callback = function()
        vim.lsp.config('lua_ls', {
            settings = {
                Lua = {
                    runtime = { version = 'LuaJIT', path = vim.split(package.path, ';') },
                    diagnostics = { globals = { 'vim' } },
                    workspace = {
                        library = vim.api.nvim_get_runtime_file('', true),
                        checkThirdParty = false,
                    },
                    format = { enable = true },
                },
            },
        })
        vim.lsp.enable 'lua_ls'
        vim.lsp.enable 'stylua'
    end
})
