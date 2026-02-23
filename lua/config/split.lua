-- ~/.config/nvim/lua/config/terminal.lua
local M = {}

-- 状态变量：存储所有终端实例
-- 结构: { buf = number, win = number, is_float = boolean }
local terminals = {}
-- 仅保留底部/全屏模式的全局状态，因为这是所有底部终端共享的
local is_fullscreen = false

-- 配置
local config = {
    height = 15,
    floating = {
        width = 0.8,
        height = 0.8,
    }
}

-- 获取窗口配置
-- is_float: boolean, 是否为浮动窗口
-- index: number, 当前终端在底部列表中的索引 (仅底部模式需要)
-- total: number, 底部终端总数 (仅底部模式需要)
local function get_window_config(is_float, index, total)
    if is_float then
        local width = math.floor(vim.o.columns * config.floating.width)
        local height = math.floor(vim.o.lines * config.floating.height)
        local cwd_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")

        return {
            relative = 'editor',
            width = width,
            height = height,
            row = math.floor((vim.o.lines - height) / 2),
            col = math.floor((vim.o.columns - width) / 2),
            style = 'minimal',
            border = 'rounded',
            title = cwd_name,
            title_pos = "center",
            zindex = 50, -- 确保浮动窗口在上方
        }
    else
        -- 底部模式：均分宽度
        local width = math.floor(vim.o.columns / total)
        local row = is_fullscreen and 1 or (vim.o.lines - config.height - 1)
        local height = is_fullscreen and (vim.o.lines - 2) or config.height
        local col = (index - 1) * width

        return {
            relative = 'editor',
            width = width,
            height = height,
            row = row,
            col = col,
            style = 'minimal',
            zindex = 10, -- 底部窗口层级较低
        }
    end
end

-- 安全跳转到上一个窗口
local function safe_prev_window()
    local prev_win = vim.fn.win_getid(vim.fn.winnr('#'))
    if prev_win and prev_win > 0 and vim.api.nvim_win_is_valid(prev_win) then
        pcall(vim.api.nvim_set_current_win, prev_win)
    else
        local wins = vim.api.nvim_list_wins()
        for _, win in ipairs(wins) do
            if win ~= vim.api.nvim_get_current_win() then
                pcall(vim.api.nvim_set_current_win, win)
                return
            end
        end
    end
end

-- 调整所有底部终端的大小 (仅处理 is_float == false 的)
local function resize_terminals()
    -- 筛选出所有有效的底部终端
    local bottom_terms = {}
    for _, term in ipairs(terminals) do
        if term.win and vim.api.nvim_win_is_valid(term.win) and not term.is_float then
            table.insert(bottom_terms, term)
        end
    end

    local total = #bottom_terms
    if total == 0 then return end

    for i, term in ipairs(bottom_terms) do
        local new_cfg = get_window_config(false, i, total)
        pcall(vim.api.nvim_win_set_config, term.win, new_cfg)
    end
end

-- 创建终端的核心逻辑
local function create_or_reuse_terminal(target_win, is_float)
    local buf = vim.api.nvim_create_buf(false, true)

    -- 计算位置
    local index = 1
    local total = 1
    if not is_float then
        total = #terminals + 1
        index = total
    end

    local win_config = get_window_config(is_float, index, total)
    local win

    if target_win and vim.api.nvim_win_is_valid(target_win) then
        win = target_win
        vim.api.nvim_win_set_buf(win, buf)
        vim.api.nvim_win_set_config(win, win_config)
    else
        win = vim.api.nvim_open_win(buf, true, win_config)
    end

    -- 隐藏 winbar (针对 Neovim 0.8+)
    pcall(vim.api.nvim_set_option_value, 'winbar', '', { win = win })

    -- 启动终端进程
    vim.fn.jobstart({ 'fish' }, { term = true })

    -- 重新获取 buffer 确保 ID 正确
    buf = vim.api.nvim_win_get_buf(win)

    -- 更新或添加到列表
    local exists = false
    for _, t in ipairs(terminals) do
        if t.win == win then
            t.buf = buf
            t.is_float = is_float -- 更新状态
            exists = true
            break
        end
    end

    if not exists then
        table.insert(terminals, { buf = buf, win = win, is_float = is_float })
    end

    vim.cmd("startinsert")
end

-- 打开或聚焦终端 (默认打开底部终端)
function M.create_terminal()
    local current_win = vim.api.nvim_get_current_win()
    for _, term in ipairs(terminals) do
        if term.win == current_win then return end
    end

    if #terminals > 0 then
        -- 清理无效终端
        for i = #terminals, 1, -1 do
            if not vim.api.nvim_win_is_valid(terminals[i].win) then
                table.remove(terminals, i)
            end
        end

        if #terminals > 0 then
            -- 优先聚焦最后一个底部终端，如果没有则聚焦任意一个
            local target = terminals[#terminals]
            for _, t in ipairs(terminals) do
                if not t.is_float then
                    target = t; break;
                end
            end

            vim.api.nvim_set_current_win(target.win)
            vim.cmd("startinsert")
            return
        end
    end

    create_or_reuse_terminal(nil, false)
end

-- 在右边分割终端 (强制创建新的底部终端)
function M.split_terminal()
    create_or_reuse_terminal(nil, false)
    resize_terminals()
end

-- 切换浮动终端
-- 如果当前聚焦的是底部终端 -> 变为浮动
-- 如果当前没有终端 -> 创建浮动
function M.open_floating()
    local current_win = vim.api.nvim_get_current_win()
    local current_term_index = nil

    -- 查找当前窗口是否在终端列表中
    for i, t in ipairs(terminals) do
        if t.win == current_win then
            current_term_index = i
            break
        end
    end

    if current_term_index then
        -- 情况A：当前聚焦的是终端 -> 切换其浮动状态
        local term = terminals[current_term_index]
        local new_float_state = not term.is_float

        if new_float_state then
            -- 切换为浮动：从列表中移除（为了不影响底部 resize 计算），重新配置，再放回
            table.remove(terminals, current_term_index)
            local cfg = get_window_config(true, 1, 1)
            vim.api.nvim_win_set_config(term.win, cfg)
            term.is_float = true
            table.insert(terminals, term)

            -- 调整剩余的底部终端
            resize_terminals()
        else
            -- 切换为底部：标记为底部，重新配置
            term.is_float = false
            local cfg = get_window_config(false, #terminals + 1, #terminals + 1) -- 暂时计算
            vim.api.nvim_win_set_config(term.win, cfg)

            -- 调整所有底部终端（包括这个新的）
            resize_terminals()
        end
        vim.cmd("startinsert")
    else
        -- 情况B：当前不在终端中 -> 尝试聚焦现有的浮动，或新建
        local has_float = false
        for _, t in ipairs(terminals) do
            if t.is_float and vim.api.nvim_win_is_valid(t.win) then
                vim.api.nvim_set_current_win(t.win)
                vim.cmd("startinsert")
                has_float = true
                break
            end
        end

        if not has_float then
            create_or_reuse_terminal(nil, true)
        end
    end
end

-- 切换全屏 (仅对底部终端有效)
function M.toggle_fullscreen()
    -- 检查是否有底部终端
    local has_bottom = false
    for _, t in ipairs(terminals) do
        if not t.is_float and vim.api.nvim_win_is_valid(t.win) then
            has_bottom = true
            break
        end
    end

    if not has_bottom then
        vim.notify("请先打开底部终端", vim.log.levels.WARN)
        return
    end

    is_fullscreen = not is_fullscreen
    resize_terminals()

    -- 如果当前在终端中，保持插入模式
    local current_win = vim.api.nvim_get_current_win()
    for _, t in ipairs(terminals) do
        if t.win == current_win then
            vim.cmd("startinsert")
            break
        end
    end
end

-- 关闭当前终端
function M.close_terminal()
    local current_win = vim.api.nvim_get_current_win()
    local index_to_remove = nil

    for i, t in ipairs(terminals) do
        if t.win == current_win then
            index_to_remove = i
            break
        end
    end

    if index_to_remove then
        local term = terminals[index_to_remove]
        local was_bottom = not term.is_float

        vim.api.nvim_win_close(term.win, true)
        table.remove(terminals, index_to_remove)

        -- 如果关闭的是底部终端，需要重新布局剩余的底部终端
        if was_bottom then
            resize_terminals()

            -- 尝试聚焦相邻的底部终端
            if #terminals > 0 then
                local focus_idx = math.max(1, math.min(index_to_remove, #terminals))
                -- 确保聚焦的是底部终端（如果存在）
                if not terminals[focus_idx].is_float then
                    vim.api.nvim_set_current_win(terminals[focus_idx].win)
                else
                    -- 如果聚焦位置变成了浮动终端，找第一个底部终端
                    for _, t in ipairs(terminals) do
                        if not t.is_float then
                            vim.api.nvim_set_current_win(t.win)
                            break
                        end
                    end
                end
            else
                safe_prev_window()
            end
        else
            -- 如果关闭的是浮动终端，检查是否还有底部终端需要调整（理论上不需要，除非之前逻辑有变）
            safe_prev_window()
        end
    else
        -- 如果当前不在终端中，关闭最后一个
        if #terminals > 0 then
            vim.api.nvim_win_close(terminals[#terminals].win, true)
            table.remove(terminals)
            resize_terminals()
        end
    end
end

-- 切换显示/隐藏终端
function M.toggle_terminal()
    if #terminals > 0 then
        M.close_all_terminals()
    else
        M.create_terminal()
    end
end

-- 关闭所有终端
function M.close_all_terminals()
    for _, t in ipairs(terminals) do
        if t.win and vim.api.nvim_win_is_valid(t.win) then
            vim.api.nvim_win_close(t.win, true)
        end
    end
    terminals = {}
    is_fullscreen = false
end

-- 设置快捷键
function M.setup()
    vim.keymap.set('n', '<leader>tt', M.toggle_terminal, { desc = '打开/隐藏终端' })
    vim.keymap.set('n', '<leader>tf', M.open_floating, { desc = '打开/切换浮动终端' })
    vim.keymap.set('n', '<leader>tm', M.toggle_fullscreen, { desc = '切换全屏' })
    vim.keymap.set('n', '<leader>tc', M.close_terminal, { desc = '关闭当前终端' })
    vim.keymap.set('n', '<leader>ts', M.split_terminal, { desc = '水平分割终端' })

    -- 终端模式
    vim.keymap.set('t', '<leader>tt', '<C-\\><C-n>:lua require("config.split").toggle_terminal()<CR>',
        { desc = '打开/隐藏终端' })
    vim.keymap.set('t', '<leader>tf', '<C-\\><C-n>:lua require("config.split").open_floating()<CR>',
        { desc = '打开/切换浮动终端' })
    vim.keymap.set('t', '<leader>tm', '<C-\\><C-n>:lua require("config.split").toggle_fullscreen()<CR>',
        { desc = '切换全屏' })
    vim.keymap.set('t', '<leader>tc', '<C-\\><C-n>:lua require("config.split").close_terminal()<CR>',
        { desc = '关闭当前终端' })
    vim.keymap.set('t', '<leader>ts', '<C-\\><C-n>:lua require("config.split").split_terminal()<CR>',
        { desc = '水平分割终端' })

    -- 自动调整大小
    vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
            resize_terminals()
        end
    })
end

return M
