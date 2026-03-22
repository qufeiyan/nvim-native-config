---@diagnostic disable: undefined-doc-name
local root_markers1 = {
    ".emmyrc.json",
    ".luarc.json",
    ".luarc.jsonc",
}
local root_markers2 = {
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
}

---@type vim.lsp.Config
return {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = vim.fn.has("nvim-0.11.3") == 1 and { root_markers1, root_markers2, { ".git" } }
        or vim.list_extend(vim.list_extend(root_markers1, root_markers2), { ".git" }),
    ---@type lspconfig.settings.lua_ls
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
                path = vim.split(package.path, ";"),
            },
            diagnostics = {
                globals = { "vim" },
            },
            workspace = {
                -- library = vim.env.VIMRUNTIME,
                -- checkThirdParty = false,
                library = vim.api.nvim_get_runtime_file("", true),
                maxPreload = 1000,
                preloadFileSize = 1000,
            },
            telemetry = { enable = false },
            codeLens = {
                enable = false,
            },
            completion = {
                callSnippet = "Replace",
            },
            doc = {
                privateName = { "^_" },
            },
        },
    },
}
