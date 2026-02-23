-- ~/.config/nvim/lua/config/terminal.lua
local M = {}

-- 状态变量：存储所有终端实例
local terminals = {}
local is_fullscreen = false

-- 配置
local config = {
    height = 15,
    floating = {
        width = 0.8,
        height = 0.8,
    }
}

-- 辅助函数：清理无效终端
local function cleanup_terminals()
    for i = #terminals, 1, -1 do
        local t = terminals[i]
        if t.win and not vim.api.nvim_win_is_valid(t.win) and not t.is_hidden then
            table.remove(terminals, i)
        end
    end
end

-- 获取窗口配置
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
            zindex = 50,
        }
    else
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
            zindex = 10,
        }
    end
end

-- 安全跳转
local function safe_prev_window()
    local current_win = vim.api.nvim_get_current_win()
    local wins = vim.api.nvim_list_wins()
    local prev_win_id = vim.fn.win_getid(vim.fn.winnr('#'))
    if prev_win_id and prev_win_id > 0 and prev_win_id ~= current_win and vim.api.nvim_win_is_valid(prev_win_id) then
        pcall(vim.api.nvim_set_current_win, prev_win_id)
        return
    end
    for _, win in ipairs(wins) do
        if win ~= current_win then
            pcall(vim.api.nvim_set_current_win, win)
            return
        end
    end
end

-- 调整大小
local function resize_terminals()
    local bottom_terms = {}
    for _, term in ipairs(terminals) do
        if term.win and vim.api.nvim_win_is_valid(term.win) and not term.is_float and not term.is_hidden then
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

-- 创建终端
local function create_or_reuse_terminal(target_win, is_float)
    local buf = vim.api.nvim_create_buf(false, true)
    local index = 1
    local total = 1
    if not is_float then
        local current_bottom_count = 0
        for _, t in ipairs(terminals) do
            if not t.is_float and not t.is_hidden then current_bottom_count = current_bottom_count + 1 end
        end
        total = current_bottom_count + 1
        index = total
    end

    local win_config = get_window_config(is_float, index, total)
    local win

    if target_win and vim.api.nvim_win_is_valid(target_win) then
        win = target_win
        vim.api.nvim_win_set_buf(win, buf)
        pcall(vim.api.nvim_win_set_config, win, win_config)
    else
        win = vim.api.nvim_open_win(buf, true, win_config)
    end

    pcall(vim.api.nvim_set_option_value, 'winbar', '', { win = win })
    vim.fn.jobstart({ 'fish' }, { term = true })
    buf = vim.api.nvim_win_get_buf(win)

    table.insert(terminals, { buf = buf, win = win, is_float = is_float, is_hidden = false })
    vim.cmd("startinsert")
end

-- ================= 新增功能：终端切换 =================

-- 获取当前有效的终端列表（按创建顺序）
local function get_active_terminals()
    local active = {}
    for _, t in ipairs(terminals) do
        if t.win and vim.api.nvim_win_is_valid(t.win) and not t.is_hidden then
            table.insert(active, t)
        end
    end
    return active
end

-- 跳转到下一个终端
function M.next_terminal()
    cleanup_terminals()
    local active_terms = get_active_terminals()
    if #active_terms == 0 then return end

    local current_win = vim.api.nvim_get_current_win()
    local next_index = 1

    -- 找到当前窗口在列表中的位置，加 1
    for i, t in ipairs(active_terms) do
        if t.win == current_win then
            next_index = i + 1
            break
        end
    end

    -- 循环处理
    if next_index > #active_terms then
        next_index = 1
    end

    vim.api.nvim_set_current_win(active_terms[next_index].win)
    if vim.bo[active_terms[next_index].buf].buftype == 'terminal' then
        vim.cmd("startinsert")
    end
end

-- 跳转到上一个终端
function M.prev_terminal()
    cleanup_terminals()
    local active_terms = get_active_terminals()
    if #active_terms == 0 then return end

    local current_win = vim.api.nvim_get_current_win()
    local prev_index = #active_terms

    -- 找到当前窗口在列表中的位置，减 1
    for i, t in ipairs(active_terms) do
        if t.win == current_win then
            prev_index = i - 1
            break
        end
    end

    -- 循环处理
    if prev_index < 1 then
        prev_index = #active_terms
    end

    vim.api.nvim_set_current_win(active_terms[prev_index].win)
    if vim.bo[active_terms[prev_index].buf].buftype == 'terminal' then
        vim.cmd("startinsert")
    end
end

-- ================= 原有功能 =================

function M.create_terminal()
    cleanup_terminals()
    local current_win = vim.api.nvim_get_current_win()
    for _, term in ipairs(terminals) do
        if term.win == current_win then return end
    end

    for _, t in ipairs(terminals) do
        if not t.is_float and not t.is_hidden and t.win and vim.api.nvim_win_is_valid(t.win) then
            vim.api.nvim_set_current_win(t.win)
            vim.cmd("startinsert")
            return
        end
    end

    create_or_reuse_terminal(nil, false)
end

function M.split_terminal()
    cleanup_terminals()
    create_or_reuse_terminal(nil, false)
    resize_terminals()
end

function M.open_floating()
    cleanup_terminals()
    local current_win = vim.api.nvim_get_current_win()
    local current_term_index = nil

    for i, t in ipairs(terminals) do
        if t.win == current_win then
            current_term_index = i
            break
        end
    end

    if current_term_index then
        local term = terminals[current_term_index]
        local new_float_state = not term.is_float

        if new_float_state then
            table.remove(terminals, current_term_index)
            local cfg = get_window_config(true, 1, 1)
            pcall(vim.api.nvim_win_set_config, term.win, cfg)
            term.is_float = true
            table.insert(terminals, term)
            resize_terminals()
        else
            term.is_float = false
            resize_terminals()
        end
        vim.cmd("startinsert")
    else
        for _, t in ipairs(terminals) do
            if t.is_float and not t.is_hidden and t.win and vim.api.nvim_win_is_valid(t.win) then
                vim.api.nvim_set_current_win(t.win)
                vim.cmd("startinsert")
                return
            end
        end
        create_or_reuse_terminal(nil, true)
    end
end

function M.toggle_fullscreen()
    cleanup_terminals()
    local bottom_terms = {}
    for _, t in ipairs(terminals) do
        if not t.is_float and not t.is_hidden and t.win and vim.api.nvim_win_is_valid(t.win) then
            table.insert(bottom_terms, t)
        end
    end

    if #bottom_terms == 0 then
        vim.notify("请先打开底部终端", vim.log.levels.WARN)
        return
    end

    is_fullscreen = not is_fullscreen
    resize_terminals()

    if vim.api.nvim_win_is_valid(bottom_terms[1].win) then
        vim.api.nvim_set_current_win(bottom_terms[1].win)
        vim.cmd("startinsert")
    end
end

function M.close_terminal()
    cleanup_terminals()
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

        pcall(vim.api.nvim_win_close, term.win, true)
        table.remove(terminals, index_to_remove)

        if was_bottom then
            resize_terminals()
            if #terminals > 0 then
                local focus_idx = math.max(1, math.min(index_to_remove, #terminals))
                if terminals[focus_idx].is_float then
                    for _, t in ipairs(terminals) do
                        if not t.is_float then
                            vim.api.nvim_set_current_win(t.win)
                            vim.cmd("startinsert")
                            break
                        end
                    end
                else
                    vim.api.nvim_set_current_win(terminals[focus_idx].win)
                end
            else
                safe_prev_window()
            end
        else
            safe_prev_window()
        end
    else
        if #terminals > 0 then
            for i = #terminals, 1, -1 do
                local t = terminals[i]
                if not t.is_float and t.win and vim.api.nvim_win_is_valid(t.win) then
                    pcall(vim.api.nvim_win_close, t.win, true)
                    table.remove(terminals, i)
                    resize_terminals()
                    break
                end
            end
        end
    end
end

function M.toggle_terminal()
    cleanup_terminals()
    local has_visible = false
    for _, t in ipairs(terminals) do
        if t.win and vim.api.nvim_win_is_valid(t.win) and not t.is_hidden then
            has_visible = true
            break
        end
    end

    if has_visible then
        for _, t in ipairs(terminals) do
            if t.win and vim.api.nvim_win_is_valid(t.win) then
                pcall(vim.api.nvim_win_close, t.win, true)
                t.win = nil
                t.is_hidden = true
            end
        end
        safe_prev_window()
    else
        if #terminals == 0 then
            create_or_reuse_terminal(nil, false)
        else
            local hidden_terms = {}
            for _, t in ipairs(terminals) do
                if t.is_hidden then table.insert(hidden_terms, t) end
            end

            for i, t in ipairs(hidden_terms) do
                local cfg = get_window_config(t.is_float, i, #hidden_terms)
                t.win = vim.api.nvim_open_win(t.buf, i == 1, cfg)
                t.is_hidden = false
            end

            if #hidden_terms > 0 then
                vim.api.nvim_set_current_win(hidden_terms[1].win)
                vim.cmd("startinsert")
            end
        end
    end
end

function M.close_all_terminals()
    for _, t in ipairs(terminals) do
        if t.win and vim.api.nvim_win_is_valid(t.win) then
            pcall(vim.api.nvim_win_close, t.win, true)
        end
        if vim.api.nvim_buf_is_valid(t.buf) then
            pcall(vim.api.nvim_buf_delete, t.buf, { force = true })
        end
    end
    terminals = {}
    is_fullscreen = false
end

function M.setup()
    -- 基础快捷键
    vim.keymap.set('n', '<leader>tt', M.toggle_terminal, { desc = '打开/隐藏终端' })
    vim.keymap.set('n', '<leader>tf', M.open_floating, { desc = '打开/切换浮动终端' })
    vim.keymap.set('n', '<leader>tm', M.toggle_fullscreen, { desc = '切换全屏' })
    vim.keymap.set('n', '<leader>tc', M.close_terminal, { desc = '关闭当前终端' })
    vim.keymap.set('n', '<leader>ts', M.split_terminal, { desc = '水平分割终端' })

    -- 【新增】终端切换快捷键
    vim.keymap.set('n', '<leader>tn', M.next_terminal, { desc = '切换到下一个终端' })
    vim.keymap.set('n', '<leader>tp', M.prev_terminal, { desc = '切换到上一个终端' })

    -- 终端模式快捷键
    vim.keymap.set('t', '<C-\\>t', '<C-\\><C-n>:lua require("config.splits").toggle_terminal()<CR>',
        { desc = '打开/隐藏终端' })
    vim.keymap.set('t', '<C-\\>f', '<C-\\><C-n>:lua require("config.splits").open_floating()<CR>',
        { desc = '打开/切换浮动终端' })
    vim.keymap.set('t', '<C-\\>m', '<C-\\><C-n>:lua require("config.splits").toggle_fullscreen()<CR>',
        { desc = '切换全屏' })
    vim.keymap.set('t', '<C-\\>c', '<C-\\><C-n>:lua require("config.splits").close_terminal()<CR>',
        { desc = '关闭当前终端' })
    -- vim.keymap.set('t', '<C-\\>n', '<C-\\><C-n>:lua require("config.splits").split_terminal()<CR>',
        -- { desc = '水平分割终端' })

    -- 【新增】终端模式下的切换 (无需退出插入模式)
    -- 注意：这里利用 Lua function 直接调用，比 <cmd> 更流畅
    vim.keymap.set('t', '<C-n>', function() M.next_terminal() end, { desc = '切换到下一个终端' })
    vim.keymap.set('t', '<C-p>', function() M.prev_terminal() end, { desc = '切换到上一个终端' })

    -- 自动调整大小
    vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
            resize_terminals()
        end
    })
end

return M
