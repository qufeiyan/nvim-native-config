----------------------
-- 自动命令 --
----------------------
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
    end
})


-- Turn off paste mode when leaving insert
vim.api.nvim_create_autocmd("InsertLeave", {
    pattern = "*",
    command = "set nopaste",
})

-- 保存前自动格式化
vim.api.nvim_create_autocmd('BufWritePre', {
    callback = function()
        local ft = vim.bo.filetype
        if ft == 'lua' then
            vim.lsp.buf.format()
        end
    end,
    pattern = '*',
})

-- vim.api.nvim_create_autocmd("VimEnter", {
--     callback = function(data)
--         local is_dir = vim.fn.isdirectory(data.file) == 1
--         if is_dir then
--             vim.defer_fn(function()
--                 require('mini.files').open(data.file)
--                 vim.cmd("bwipeout #") -- 关闭空缓冲区
--             end, 10)
--         end
--     end,
-- })

-- 复制高亮提示
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'highlight copying text',
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function()
        vim.highlight.on_yank({ timeout = 200 })
    end,
})

-- Restore cursor position
vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
    pattern = { '*' },
    callback = function()
        vim.api.nvim_exec2('silent! normal! g`"zv', { output = false })
    end,
})



local reset_overseerlist_width = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
        if ft == "OverseerList" then
            local target_width = math.floor(vim.o.columns * 0.2)
            vim.api.nvim_win_set_width(win, target_width)
            break
        end
    end
end
vim.api.nvim_create_autocmd('VimResized', {
    pattern = '*',
    callback = function()
        -- File buffers
        vim.cmd 'wincmd =' -- Equalize window sizes

        -- DAP UI
        -- custom_utils.func_on_window('dapui_stacks', function()
        --     require 'dapui'.open({ reset = true })
        -- end)

        -- OverseerList
        reset_overseerlist_width()
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function()
        vim.opt.formatoptions:remove({ "r", "o" })
    end
})
