if vim.b.did_my_ftplugin then
    return
end
vim.b.did_my_ftplugin = true

vim.lsp.enable("rust_analyzer")

vim.api.nvim_create_autocmd("BufReadPost", {
    once = true,
    callback = function()
        vim.lsp.config("rust_analyzer", {
            cmd = { "rust-analyzer" },
            filetypes = { "rust" },
        })
    end,
})
