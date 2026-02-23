-- ~/.config/nvim/lua/config/terminal.lua
local M = {}

-- 状态变量
local term_buf = nil
local term_win = nil
local is_fullscreen = false
local is_floating = false

-- 配置
local config = {
    height = 15,
    floating = {
        width = 0.8,
        height = 0.8,
    }
}

-- 获取窗口配置
local function get_window_config()
    if is_floating then
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
        }
    else
        return {
            relative = 'editor',
            width = vim.o.columns,
            height = is_fullscreen and (vim.o.lines - 2) or config.height,
            row = is_fullscreen and 1 or (vim.o.lines - config.height - 1),
            col = 0,
            style = 'minimal'
        }
    end
end

-- 创建或聚焦终端
function M.create_terminal()
    -- 如果窗口存在且有效，直接聚焦
    if term_win and vim.api.nvim_win_is_valid(term_win) then
        vim.api.nvim_set_current_win(term_win)
        vim.cmd("startinsert")
        return
    end

    -- 如果buffer存在但窗口不存在，重新创建窗口
    if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
        term_win = vim.api.nvim_open_win(term_buf, true, get_window_config())
        vim.cmd("startinsert")
        return
    end

    -- 创建新终端
    term_buf = vim.api.nvim_create_buf(false, true)
    term_win = vim.api.nvim_open_win(term_buf, true, get_window_config())

    -- 正确启动终端进程
    -- vim.cmd("terminal fish")
    vim.cmd("terminal zsh")

    -- 等待终端进程启动
    vim.defer_fn(function()
        -- 获取当前窗口的缓冲区（应该是终端缓冲区）
        local current_buf = vim.api.nvim_get_current_buf()

        -- 如果当前缓冲区是终端，更新 term_buf
        if vim.bo[current_buf].buftype == "terminal" then
            term_buf = current_buf
        end

        vim.cmd("startinsert")
    end, 10)
end

-- 切换下方终端：如果已打开则隐藏，否则打开
function M.toggle_terminal()
    is_floating = false
    if term_win and vim.api.nvim_win_is_valid(term_win) then
        M.close_terminal()
    else
        M.create_terminal()
    end
end

-- 打开浮动终端
function M.open_floating()
    is_floating = true
    is_fullscreen = false
    M.create_terminal()
end

-- 切换全屏
function M.toggle_fullscreen()
    if is_floating then
        vim.notify("浮动终端不支持全屏", vim.log.levels.WARN)
        return
    end

    if not term_win or not vim.api.nvim_win_is_valid(term_win) then
        vim.notify("请先打开终端", vim.log.levels.WARN)
        return
    end

    is_fullscreen = not is_fullscreen
    vim.api.nvim_win_set_config(term_win, get_window_config())
    vim.cmd("startinsert")
end

-- 关闭终端
function M.close_terminal()
    if term_win and vim.api.nvim_win_is_valid(term_win) then
        vim.api.nvim_win_close(term_win, true)
        term_win = nil
    end
end

-- 设置快捷键
function M.setup()
    -- 普通模式快捷键
    vim.keymap.set('n', '<leader>tt', M.toggle_terminal, { desc = '打开/隐藏终端' })
    vim.keymap.set('n', '<leader>tf', M.open_floating, { desc = '打开浮动终端' })
    vim.keymap.set('n', '<leader>tm', M.toggle_fullscreen, { desc = '切换全屏' })
    vim.keymap.set('n', '<leader>tc', M.close_terminal, { desc = '关闭终端' })

    -- 终端模式快捷键（使用 <C-\><C-n> 退出插入模式后执行命令）
    vim.keymap.set('t', '<C-t><C-t>', '<C-\\><C-n>:lua require("config.terminal").toggle_terminal()<CR>',
        { desc = '打开/隐藏终端' })
    vim.keymap.set('t', '<C-t><C-f>', '<C-\\><C-n>:lua require("config.terminal").open_floating()<CR>',
        { desc = '打开浮动终端' })
    vim.keymap.set('t', '<C-t><C-m>', '<C-\\><C-n>:lua require("config.terminal").toggle_fullscreen()<CR>',
        { desc = '切换全屏' })
    vim.keymap.set('t', '<C-t><C-c>', '<C-\\><C-n>:lua require("config.terminal").close_terminal()<CR>',
        { desc = '关闭终端' })
end

return M
