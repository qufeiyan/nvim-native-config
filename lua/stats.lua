local M = {}

function M.startup()
    M.startuptime = vim.loop.hrtime()
end

function M.elapsed()
    local now = vim.loop.hrtime()
    return (now - M.startuptime) / 1e6
end

--- 解析一个已加载 Lua 模块对应的磁盘文件路径。
--- @param modname string 模块名，例如 "snacks"
--- @return string|nil 模块文件绝对路径，无法解析时返回 nil
local function resolve_modpath(modname)
    local ok, found = pcall(vim.loader.find, modname)
    if not ok or type(found) ~= "table" or #found == 0 then
        return nil
    end
    return found[1].modpath
end

--- 统计插件加载情况。
--- 注意：vim.pack.get() 返回的 `active` 只表示插件在本会话被 vim.pack.add()
--- 声明过（即配置文件被 require），并不代表真正被 require 加载。
--- 这里以 package.loaded 中是否存在该插件的模块为准，判定插件是否「真正加载」。
function M.stats()
    local plugins = vim.pack.get()
    local stats = {
        total = #plugins, -- 磁盘上受 vim.pack 管理的全部插件
        active = 0, -- 已声明（vim.pack.add 被调用）
        loaded = 0, -- 真正被 require 加载
        lazy = 0, -- 已声明但尚未加载（懒加载中）
        disabled = 0, -- 未声明（配置文件被注释/未 require）
        details = {},
    }

    -- 插件根路径 -> 插件名
    local roots = {}
    for _, plugin in ipairs(plugins) do
        roots[plugin.path] = plugin.spec.name
    end

    -- 已加载模块 -> 插件名
    local loaded_names = {}
    for modname, value in pairs(package.loaded) do
        if value ~= nil and type(modname) == "string" then
            local modpath = resolve_modpath(modname)
            -- 只关心落在 vim.pack 插件目录下的模块（site/pack），
            -- 跳过内置库（ffi/lpeg/luv 等）和本配置自身的 lua/ 模块
            if modpath and modpath:find("site/pack", 1, true) then
                for root, name in pairs(roots) do
                    local prefix = root .. "/"
                    if modpath:sub(1, #prefix) == prefix then
                        loaded_names[name] = true
                        break
                    end
                end
            end
        end
    end

    for _, plugin in ipairs(plugins) do
        local loaded = loaded_names[plugin.spec.name] == true
        if plugin.active then
            stats.active = stats.active + 1
            if loaded then
                stats.loaded = stats.loaded + 1
            else
                stats.lazy = stats.lazy + 1
            end
        else
            stats.disabled = stats.disabled + 1
        end
        table.insert(stats.details, {
            name = plugin.spec.name,
            active = plugin.active,
            loaded = loaded,
        })
    end

    return stats
end

local function print_stats()
    local stats = M.stats()
    local msg = string.format(
        "📊 插件统计：总%d个 | 已加载%d个 | 懒加载%d个 | 未启用%d个",
        stats.total,
        stats.loaded,
        stats.lazy,
        stats.disabled
    )

    vim.notify(msg, vim.log.levels.INFO)
    print("\n" .. msg)
    print("----------------------------------------")
    for _, detail in ipairs(stats.details) do
        local status
        if detail.loaded then
            status = "✅" -- 真正加载
        elseif detail.active then
            status = "⏳" -- 懒加载（已声明未触发）
        else
            status = "❌" -- 未启用（未声明）
        end
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
            string.format("⚡ Neovim loaded %d/%d plugins 󰏖 in %.2fms", stats.loaded, stats.active, M.elapsed())
        -- vim.notify(msg)
        vim.env.NVIM_STARTUP = msg
    end,
})

M.startup()
return M
