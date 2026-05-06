M = {}

function M.startup()
    M.startuptime = vim.loop.hrtime()
end

function M.elapsed()
    local now = vim.loop.hrtime()
    return (now - M.startuptime) / 1e6
end

function M.stats()
    local plugins = vim.pack.get()
    local stats = {
        total = #plugins,
        loaded = 0,
        unloaded = 0,
        details = {},
    }

    for _, plugin in ipairs(plugins) do
        if plugin.active then
            stats.loaded = stats.loaded + 1
        end
        table.insert(stats.details, {
            name = plugin.spec.name,
            active = plugin.active,
        })
    end
    stats.unloaded = stats.total - stats.loaded
    return stats
end

local function print_stats()
    local stats = M.stats()
    local msg = string.format(
        "📊 插件加载统计：总%d个 | 已加载%d个 | 未加载%d个",
        stats.total,
        stats.loaded,
        stats.unloaded
    )

    vim.notify(msg, vim.log.levels.INFO)
    print("\n" .. msg)
    print("----------------------------------------")
    for _, detail in ipairs(stats.details) do
        local status = detail.active and "✅" or "❌"
        print(string.format("%s %s", status, detail.name))
    end
end

vim.api.nvim_create_user_command("PluginLoadStats", function()
    print_stats()
end, { desc = "显示插件加载统计信息" })

vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        local stats = M.stats()
        local msg =
            string.format("⚡ Neovim loaded %d/%d plugins 󰏖 in %.2fms", stats.loaded, stats.total, M.elapsed())
        -- vim.notify(msg)
        vim.env.NVIM_STARTUP = msg
    end,
})

M.startup()
return M
