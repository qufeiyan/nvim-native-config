local M = {}

-- 1. 创建命名空间
local ns_id = vim.api.nvim_create_namespace("InlineMultiArgb")

-- 2. 核心转换函数：ARGB1555 -> ARGB8888 字符串 (#AARRGGBB)
local function argb1555_to_argb8888(argb_val)
    local bit = require("bit")
    local a_bit = bit.band(bit.rshift(argb_val, 15), 0x1)

    -- bit 10-14: Red (5 bits)
    local r = bit.band(bit.rshift(argb_val, 10), 0x1F)

    -- bit 5-9: Green (5 bits)
    local g = bit.band(bit.rshift(argb_val, 5), 0x1F)

    -- bit 0-4: Blue (5 bits)
    local b = bit.band(argb_val, 0x1F)

    -- 扩展到 8 位 (0-255)
    -- Alpha: 1 变 255, 0 变 0
    local a8 = (a_bit == 1) and 255 or 0

    -- 颜色分量: (x * 255) / 31
    local r8 = math.floor((r * 255) / 31)
    local g8 = math.floor((g * 255) / 31)
    local b8 = math.floor((b * 255) / 31)

    return string.format("#%02X%02X%02X", a8, r8, g8, b8)
    -- return string.format("#%02X%02X%02X%02X", a8, r8, g8, b8)
end

function M.show_inline_preview()
    local bufnr = 0
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local line_content = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]

    -- 先清除当前行旧的虚拟文本，防止重复叠加
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, row, row + 1)

    -- 循环查找所有匹配项 (格式：0xXXXX)
    local start_idx, end_idx, match_str
    local last_end_idx = 1

    while true do
        -- 查找 0x 开头后跟 4 个十六进制字符
        start_idx, end_idx = line_content:find("0x[0-9a-fA-F]+", last_end_idx)

        if not start_idx or not end_idx then
            break
        end

        match_str = line_content:sub(start_idx, end_idx)
        local val = tonumber(match_str, 16)
        if val then
            local hex_argb = argb1555_to_argb8888(val)

            -- 生成唯一的高亮组名，防止冲突
            local hl_group_name = "InlineArgb_" .. match_str:sub(2)
            vim.api.nvim_set_hl(ns_id, hl_group_name, {
                bg = hex_argb,
                fg = "none",
            })

            local win_id = vim.api.nvim_get_current_win()
            vim.api.nvim_win_set_hl_ns(win_id, ns_id)

            -- 添加虚拟文本
            -- end_idx 是匹配字符串的最后一个字符的索引 (Lua 1-based)
            -- extmark 的 col 参数是 0-based，正好对应 end_idx
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, row, end_idx, {
                virt_text = { { " :" .. hex_argb .. " ", hl_group_name } },
                virt_text_pos = "inline", -- 关键：行内插入，挤开后续代码
                -- hl_mode = "combine",      -- 混合高亮模式
                priority = 200,           -- 提高优先级，防止被覆盖
            })
        end

        -- 更新下一次查找的起始位置
        last_end_idx = end_idx + 1
        -- print("end:" .. end_idx .. "match" .. match_str .. "")
    end
end

-- 5. 清除功能：清除当前 Buffer 所有预览
function M.clear_all_preview()
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    vim.notify("已清除 ARGB 颜色预览", "info")
end

-- 6. 设置快捷键
vim.keymap.set('n', '<leader>h', M.show_inline_preview, {
    desc = "显示当前行 ARGB1555 颜色预览"
})

vim.keymap.set('n', '<leader>H', M.clear_all_preview, {
    desc = "清除所有颜色预览"
})

-- 7. 自动事件处理
-- 保存前清除，防止 Git Diff 报错或视觉残留
vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function()
        if vim.api.nvim_buf_is_valid(0) then
            vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
        end
    end
})

-- 可选：离开插入模式时自动清除，保持编辑界面整洁
vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
        if vim.api.nvim_buf_is_valid(0) then
            vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
        end
    end
})

return M
