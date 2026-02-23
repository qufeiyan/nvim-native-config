M = {}

function M.startup()
    M.startuptime = vim.loop.hrtime()
end

-- reurn ms elapsed
function M.elapsed()
    local now = vim.loop.hrtime()
    return (now - M.startuptime) / 1e6
end

M.config = {
    map_file = vim.fn.stdpath("config") .. "/plugin_module_maps.json",
    ignore_dirs = { ".git", "doc", "tests", "lua", "after" },
}

local function scan_plugin_dirs()
    local plugins = {
        opt = {},
        start = {}
    }
    local xdg_data = vim.fn.stdpath("data")
    local opt_path = xdg_data .. "/site/pack/core/opt/"

    -- 扫描start目录（默认加载）
    for _, dir in ipairs(vim.fn.glob(xdg_data .. "/site/pack/*/start", false, true)) do
        if vim.fn.isdirectory(dir) == 1 then
            for _, start_dir in ipairs(vim.fn.readdir(dir)) do
                local name = vim.fn.fnamemodify(start_dir, ":t")
                if not vim.tbl_contains(M.config.ignore_dirs, name) then
                    table.insert(plugins.start, { path = dir, dir_name = name })
                end
            end
        end
    end

    -- 扫描opt目录（按需加载）
    for _, dir in ipairs(vim.fn.readdir(opt_path)) do
        if vim.fn.isdirectory(opt_path .. "/" .. dir) == 1 then
            local name = vim.fn.fnamemodify(dir, ":t")
            if not vim.tbl_contains(M.config.ignore_dirs, name) then
                table.insert(plugins.opt, { path = dir, dir_name = name })
            end
        end
    end

    return plugins
end

local function load_mapping_file()
    local mapping_path = M.config.map_file
    if vim.fn.filereadable(mapping_path) == 1 then
        local file = io.open(mapping_path, "r")
        if file ~= nil then
            local content = file:read("*all")
            file:close()
            return vim.fn.json_decode(content)
        end
    end
    return {}
end

local function get_module_name(dir_name, mapping)
    -- 检查映射文件中是否有自定义映射
    if mapping[dir_name] then
        return mapping[dir_name]
    end

    -- 默认规则：将目录名转换为Lua模块名
    -- 例如：my-plugin -> my_plugin
    return dir_name:gsub("%.nvim$", "")
end

local function check_plugin_loaded(module_name)
    -- 检查Lua模块是否已加载
    if package.loaded[module_name] then
        return true
    end

    -- 检查Vimscript插件是否已加载
    local script_name = module_name:gsub("_", "-") .. ".vim"
    if vim.fn.exists(":command " .. script_name) == 2 then
        return true
    end

    return false
end

function M.stats()
    local plugins = scan_plugin_dirs()
    local maps = load_mapping_file()
    local total_plugins = #plugins.start + #plugins.opt
    local stats = {
        total = total_plugins,
        loaded = 0,
        unloaded = 0,
        details = {},
    }

    for _, plugin_items in ipairs(plugins.start) do
        local module_dir_name = plugin_items.dir_name
        local module_name = get_module_name(module_dir_name, maps)
        if check_plugin_loaded(module_name) then
            stats.loaded = stats.loaded + 1
            table.insert(stats.details, {
                dir_name = module_dir_name,
                module_name = module_name,
                type = "start",
                loaded = stats.loaded
            })
        end
    end

    for _, plugin_items in ipairs(plugins.opt) do
        local module_dir_name = plugin_items.dir_name
        local module_name = get_module_name(module_dir_name, maps)
        if check_plugin_loaded(module_name) then
            stats.loaded = stats.loaded + 1
            table.insert(stats.details, {
                dir_name = module_dir_name,
                module_name = module_name,
                type = "opt",
                loaded = stats.loaded
            })
        end
    end
    return stats
end

local function print_stats()
    local stats = M.stats()
    local msg = string.format(
        "📊 插件加载统计：总%d个 | 已加载%d个 | 未加载%d个",
        stats.total,
        stats.loaded,
        stats.total - stats.loaded
    )

    -- 打印详细信息（仅在命令行模式下显示）
    vim.notify(msg, vim.log.levels.INFO)
    print("\n" .. msg)
    print("----------------------------------------")
    for _, detail in ipairs(stats.details) do
        local status = detail.loaded and "✅" or "❌"
        print(string.format(
            "%s %s（类型：%s）| 模块名：%s",
            status,
            detail.dir_name,
            detail.type,
            detail.module_name
        ))
    end
end

-- 注册手动刷新命令
vim.api.nvim_create_user_command("PluginLoadStats", function()
    print_stats()
end, { desc = "显示插件加载统计信息" })

vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        local stats = M.stats()
        local msg = string.format(
            "⚡ Neovim loaded %d/%d plugins 󰏖 in %.2fms",
            stats.loaded,
            stats.total,
            M.elapsed()
        )
        vim.notify(msg)
        vim.env.NVIM_STARTUP = msg
    end
})

M.startup()
return M
