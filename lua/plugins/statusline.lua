vim.pack.add({
    { src = "https://github.com/nvim-mini/mini.statusline" },
})
local function statusline_setup()
    local attached_lsp = {}
    local copilot = nil
    local compute_attached_lsp = function(buf_id)
        local names = {}
        for _, server in pairs(vim.lsp.get_clients({ bufnr = buf_id })) do
            if server.name == "copilot" then
                copilot = ""
            else
                table.insert(names, server.name)
            end
        end

        local lsps = table.concat(names, ", ")
        return lsps
    end
    vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
        pattern = "*",
        callback = function(arg)
            local fn = vim.schedule_wrap(function(data)
                attached_lsp[data.buf] = vim.api.nvim_buf_is_valid(data.buf) and compute_attached_lsp(data.buf) or nil
                vim.cmd("redrawstatus")
            end)
            fn(arg)
        end,
    })

    local sl = require("mini.statusline")
    sl.setup({
        content = {
            -- Content for active window
            active = function()
                local mode, mode_hl = sl.section_mode({ trunc_width = 120 })
                local git = sl.section_git({ trunc_width = 40 })
                local diff = sl.section_diff({ trunc_width = 75 })
                local diagnostics = sl.section_diagnostics({ trunc_width = 75 })
                -- local lsp = sl.section_lsp({ trunc_width = 75 })
                -- local filename = sl.section_filename({ trunc_width = 140 })
                local fileinfo = sl.section_fileinfo({ trunc_width = 120 })
                -- local location = sl.section_location({ trunc_width = 75 })
                local search = sl.section_searchcount({ trunc_width = 75 })
                local section_filename = function(args)
                    -- In terminal always use plain name
                    if vim.bo.buftype == "terminal" then
                        return "%t"
                    else
                        local cwd = vim.fn.getcwd()
                        local bufnr = vim.api.nvim_get_current_buf()
                        local buf_path = vim.api.nvim_buf_get_name(bufnr)
                        local relative_path = vim.fs.relpath(cwd, buf_path)
                        local function compress_path(path)
                            if not path or path == "" then
                                return ""
                            end

                            local normalized = vim.fs.normalize(path)

                            local home = vim.fn.expand("~")
                            local is_home_path = normalized:sub(1, #home) == home

                            if is_home_path then
                                if #normalized == #home then
                                    normalized = "~"
                                else
                                    normalized = "~" .. normalized:sub(#home + 1)
                                end
                            end

                            local parts = vim.split(normalized, "/")
                            parts = vim.tbl_filter(function(v)
                                return v ~= ""
                            end, parts)

                            if #parts <= 1 then
                                return normalized
                            end

                            local compressed = {}
                            for i = 1, #parts - 1 do
                                local dir = parts[i]
                                if dir == ".." then
                                    table.insert(compressed, "..")
                                elseif dir:sub(1, 1) == "." then
                                    table.insert(compressed, dir:sub(1, 2))
                                else
                                    table.insert(compressed, dir:sub(1, 1))
                                end
                            end
                            table.insert(compressed, parts[#parts])

                            local result = table.concat(compressed, "/")
                            if not is_home_path and normalized:sub(1, 1) == "/" then
                                result = "/" .. result
                            end

                            return result
                        end

                        local modified_icon = " " -- "[+]"
                        local readonly_icon = " " -- "[RO]"
                        local modified = vim.api.nvim_get_option_value("modified", { buf = bufnr }) and modified_icon
                            or ""
                        local readonly = vim.api.nvim_get_option_value("readonly", { buf = bufnr }) and readonly_icon
                            or ""
                        local addon = modified .. readonly

                        local path = relative_path or buf_path
                        if sl.is_truncated(args.trunc_width) then
                            return compress_path(path) .. addon
                        end

                        return relative_path and relative_path .. addon or compress_path(buf_path) .. addon
                    end
                end
                local filename = section_filename({ trunc_width = 140 })

                local section_lsp = function(args)
                    if sl.is_truncated(args.trunc_width) then
                        return ""
                    end

                    local attached = attached_lsp[vim.api.nvim_get_current_buf()] or ""

                    if attached == "" then
                        return ""
                    end

                    return " " .. attached
                end

                local lsp = section_lsp({ trunc_width = 75 })
                vim.api.nvim_set_hl(0, "CopilotInfo", { fg = "#61AfEF" })
                vim.api.nvim_set_hl(0, "AttachedLSPInfo", { fg = "#d3869b", italic = true })

                local function section_location(args)
                    if sl.is_truncated(args.trunc_width) then
                        return "%l:%2v"
                    end

                    local current_line = vim.fn.line(".")
                    local total_lines = vim.fn.line("$")
                    local current_col = vim.fn.virtcol(".")
                    local line_percentage = 0
                    if total_lines > 0 then
                        line_percentage = (current_line / total_lines) * 100
                    end
                    local location = string.format("%d:%-2d %d", current_line, current_col, line_percentage)

                    return " " .. location .. "%%"
                end
                local function section_scrollbar()
                    local current_line = vim.fn.line(".")
                    local total_lines = vim.fn.line("$")
                    local sbar = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }
                    local i = math.floor((current_line - 1) / total_lines * #sbar) + 1
                    return string.rep(sbar[i], 2)
                end
                local bar = section_scrollbar()
                vim.api.nvim_set_hl(0, "Scrollbar", { fg = "#fe8019", bg = "none" })
                vim.api.nvim_set_hl(0, "@ClockInfo", { link = "Scrollbar" })

                local location = section_location({ trunc_width = 45 })

                local function section_time()
                    local time = os.date("%H:%M") -- show hour and minute in 24 hour format
                    local clock_icon = "󰀡 " -- add icon for clock
                    return clock_icon .. time
                end
                local time = section_time()

                -- Usage of `MiniStatusline.combine_groups()` ensures highlighting and
                -- correct padding with spaces between groups (accounts for 'missing'
                -- sections, etc.)
                return sl.combine_groups({
                    { hl = mode_hl, strings = { mode } },
                    { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics } },
                    { hl = "CopilotInfo", strings = { copilot or "" } },
                    "%<", -- Mark general truncate point
                    { hl = "MiniStatuslineFilename", strings = { filename } },
                    "%=", -- End left alignment
                    { hl = "AttachedLSPInfo", strings = { lsp } },
                    { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
                    { hl = "Search", strings = { search } },
                    { hl = mode_hl, strings = { location } },
                    -- { hl = "Scrollbar",              strings = { bar } },
                    { hl = "@ClockInfo", strings = { time } },
                })
            end,
            -- Content for inactive window(s)
            inactive = nil,
        },

        -- Whether to use icons by default
        use_icons = true,
    })
end

vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        vim.defer_fn(function()
            statusline_setup()
        end, 100)
    end,
})
