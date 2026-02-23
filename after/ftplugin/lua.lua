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
                    runtime = { version = 'LuaJIT', path = vim.split(package.path, ';') }, -- Lua 运行时
                    diagnostics = { globals = { 'vim' } },                                 -- 忽略全局变量 vim 的警告
                    workspace = {
                        library = vim.api.nvim_get_runtime_file('', true),
                        checkThirdParty = false,
                    },
                    format = { enable = true }, -- 启用格式化
                },
            },
        })
        vim.lsp.enable 'lua_ls'
        vim.lsp.enable 'stylua'
    end
})
