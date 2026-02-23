local M = {}

local config = {
    markers = {
        ours = "^<<<<<<<+",
        separator = "^=======+$",
        ancestor = "^|||||||+",
        theirs = "^>>>>>>>+",
    },
    default_keymaps = true,
    on_conflict_detected = nil,
    on_conflicts_resolved = nil,
}

local state = {
    namespace = nil,
    augroup = nil,
    conflicts = {},
}

--- Setup highlights
local function setup_highlights()
    local is_dark = vim.o.background == "dark"

    local hl = is_dark and {
        ours_marker = { bg = "#3d5c3d", bold = true },
        theirs_marker = { bg = "#3d4d5c", bold = true },
        separator_marker = { bg = "#4a4a4a", bold = true },
        ancestor_marker = { bg = "#5c4d3d", bold = true },
        ours_section = { bg = "#2a3a2a" },
        theirs_section = { bg = "#2a2f3a" },
        ancestor_section = { bg = "#3a322a" },
    } or {
        ours_marker = { bg = "#a0d0a0", bold = true },
        theirs_marker = { bg = "#a0c0e0", bold = true },
        separator_marker = { bg = "#c0c0c0", bold = true },
        ancestor_marker = { bg = "#e0c898", bold = true },
        ours_section = { bg = "#e8f4e8" },
        theirs_section = { bg = "#e8ecf4" },
        ancestor_section = { bg = "#f4ece8" },
    }

    local function set_hl(name, opts)
        vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", opts, { default = true }))
    end

    set_hl("ResolveOursMarker", hl.ours_marker)
    set_hl("ResolveTheirsMarker", hl.theirs_marker)
    set_hl("ResolveSeparatorMarker", hl.separator_marker)
    set_hl("ResolveAncestorMarker", hl.ancestor_marker)
    set_hl("ResolveOursSection", hl.ours_section)
    set_hl("ResolveTheirsSection", hl.theirs_section)
    set_hl("ResolveAncestorSection", hl.ancestor_section)
end

--- Setup plug mappings
local function setup_plug_mappings()
    vim.keymap.set("n", "<Plug>(resolve-next)", M.next_conflict, { desc = "Next conflict" })
    vim.keymap.set("n", "<Plug>(resolve-prev)", M.prev_conflict, { desc = "Previous conflict" })
    vim.keymap.set("n", "<Plug>(resolve-ours)", M.choose_ours, { desc = "Choose ours" })
    vim.keymap.set("n", "<Plug>(resolve-theirs)", M.choose_theirs, { desc = "Choose theirs" })
    vim.keymap.set("n", "<Plug>(resolve-both)", M.choose_both, { desc = "Choose both" })
    vim.keymap.set("n", "<Plug>(resolve-both-reverse)", M.choose_both_reverse, { desc = "Choose both reverse" })
    vim.keymap.set("n", "<Plug>(resolve-base)", M.choose_base, { desc = "Choose base" })
    vim.keymap.set("n", "<Plug>(resolve-none)", M.choose_none, { desc = "Choose none" })
    vim.keymap.set("n", "<Plug>(resolve-list)", M.list_conflicts, { desc = "List conflicts" })
end

--- Setup buffer keymaps
local function setup_buffer_keymaps(bufnr)
    if vim.b[bufnr].resolve_keymaps_set then
        return
    end

    local opts = { buffer = bufnr, silent = true }

    vim.keymap.set("n", "<leader>gc", "", vim.tbl_extend("force", opts, { desc = "+Git Conflicts" }))

    vim.keymap.set("n", "]x", "<Plug>(resolve-next)",
        vim.tbl_extend("force", opts, { desc = "Next conflict", remap = true }))
    vim.keymap.set("n", "[x", "<Plug>(resolve-prev)",
        vim.tbl_extend("force", opts, { desc = "Previous conflict", remap = true }))
    vim.keymap.set("n", "<leader>gco", "<Plug>(resolve-ours)",
        vim.tbl_extend("force", opts, { desc = "Ours", remap = true }))
    vim.keymap.set("n", "<leader>gct", "<Plug>(resolve-theirs)",
        vim.tbl_extend("force", opts, { desc = "Theirs", remap = true }))
    vim.keymap.set("n", "<leader>gcb", "<Plug>(resolve-both)",
        vim.tbl_extend("force", opts, { desc = "Both", remap = true }))
    vim.keymap.set("n", "<leader>gcB", "<Plug>(resolve-both-reverse)",
        vim.tbl_extend("force", opts, { desc = "Both reverse", remap = true }))
    vim.keymap.set("n", "<leader>gcm", "<Plug>(resolve-base)",
        vim.tbl_extend("force", opts, { desc = "Base", remap = true }))
    vim.keymap.set("n", "<leader>gcn", "<Plug>(resolve-none)",
        vim.tbl_extend("force", opts, { desc = "None", remap = true }))
    vim.keymap.set("n", "<leader>gcl", "<Plug>(resolve-list)",
        vim.tbl_extend("force", opts, { desc = "List", remap = true }))

    vim.b[bufnr].resolve_keymaps_set = true
end

--- Remove buffer keymaps
local function remove_buffer_keymaps(bufnr)
    if not vim.b[bufnr].resolve_keymaps_set then
        return
    end

    local keys = { "]x", "[x", "<leader>gc", "<leader>gco", "<leader>gct", "<leader>gcb",
        "<leader>gcB", "<leader>gcm", "<leader>gcn", "<leader>gcl" }

    for _, key in ipairs(keys) do
        pcall(vim.keymap.del, "n", key, { buffer = bufnr })
    end

    vim.b[bufnr].resolve_keymaps_set = nil
end

--- Setup matchit
local function setup_matchit(bufnr)
    local match_words = vim.b[bufnr].match_words or ""
    local conflict_pairs = "<<<<<<<:|||||||:=======:>>>>>>>"
    if not match_words:find("<<<<<<<", 1, true) then
        vim.b[bufnr].match_words = match_words .. (match_words ~= "" and "," or "") .. conflict_pairs
        vim.b[bufnr].resolve_matchit_set = true
    end
end

--- Remove matchit
local function remove_matchit(bufnr)
    if not vim.b[bufnr].resolve_matchit_set then
        return
    end
    local match_words = vim.b[bufnr].match_words or ""
    local conflict_pairs = "<<<<<<<:|||||||:=======:>>>>>>>"
    match_words = match_words:gsub("," .. vim.pesc(conflict_pairs), "")
    match_words = match_words:gsub(vim.pesc(conflict_pairs) .. ",?", "")
    vim.b[bufnr].match_words = match_words == "" and nil or match_words
    vim.b[bufnr].resolve_matchit_set = nil
end

--- Scan conflicts
local function scan_conflicts()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local conflicts = {}
    local current = {}

    for i, line in ipairs(lines) do
        if line:match(config.markers.ours) then
            current = { start = i, ours_start = i }
        elseif line:match(config.markers.ancestor) and current.start then
            current.ancestor = i
        elseif line:match(config.markers.separator) and current.start then
            current.separator = i
        elseif line:match(config.markers.theirs) and current.start then
            current.theirs_end = i
            current["end"] = i
            table.insert(conflicts, current)
            current = {}
        end
    end

    return conflicts
end

--- Get current conflict
local function get_current_conflict()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local current_line = cursor[1]
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local line_count = #lines

    local ours_start = nil
    for i = current_line, 1, -1 do
        if lines[i]:match(config.markers.theirs) then
            return nil
        elseif lines[i]:match(config.markers.ours) then
            ours_start = i
            break
        end
    end

    if not ours_start then
        return nil
    end

    local ancestor, separator, theirs_end
    for i = ours_start + 1, line_count do
        local line = lines[i]
        if line:match(config.markers.ours) then
            return nil
        elseif line:match(config.markers.ancestor) and not separator then
            ancestor = i
        elseif line:match(config.markers.separator) then
            separator = i
        elseif line:match(config.markers.theirs) then
            theirs_end = i
            break
        end
    end

    if not separator or not theirs_end then
        return nil
    end

    if current_line > theirs_end then
        return nil
    end

    return {
        start = ours_start,
        ours_start = ours_start,
        ancestor = ancestor,
        separator = separator,
        theirs_end = theirs_end,
        ["end"] = theirs_end
    }
end

--- Highlight conflicts
local function highlight_conflicts(conflicts)
    local bufnr = vim.api.nvim_get_current_buf()
    state.namespace = state.namespace or vim.api.nvim_create_namespace("resolve_conflicts")
    local ns_id = state.namespace

    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

    for _, c in ipairs(conflicts) do
        vim.api.nvim_buf_set_extmark(bufnr, ns_id, c.ours_start - 1, 0, {
            end_col = 0, end_row = c.ours_start, hl_group = "ResolveOursMarker", hl_eol = true,
        })

        if c.ancestor then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, c.ancestor - 1, 0, {
                end_col = 0, end_row = c.ancestor, hl_group = "ResolveAncestorMarker", hl_eol = true,
            })
        end

        vim.api.nvim_buf_set_extmark(bufnr, ns_id, c.separator - 1, 0, {
            end_col = 0, end_row = c.separator, hl_group = "ResolveSeparatorMarker", hl_eol = true,
        })

        vim.api.nvim_buf_set_extmark(bufnr, ns_id, c.theirs_end - 1, 0, {
            end_col = 0, end_row = c.theirs_end, hl_group = "ResolveTheirsMarker", hl_eol = true,
        })

        local ours_end = c.ancestor and (c.ancestor - 1) or (c.separator - 1)
        if ours_end > c.ours_start then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, c.ours_start, 0, {
                end_row = ours_end, end_col = 0, hl_group = "ResolveOursSection", hl_eol = true,
            })
        end

        if c.ancestor and c.separator - 1 > c.ancestor then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, c.ancestor, 0, {
                end_row = c.separator - 1, end_col = 0, hl_group = "ResolveAncestorSection", hl_eol = true,
            })
        end

        if c.theirs_end - 1 > c.separator then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, c.separator, 0, {
                end_row = c.theirs_end - 1, end_col = 0, hl_group = "ResolveTheirsSection", hl_eol = true,
            })
        end
    end
end

--- Main detect function
function M.detect_conflicts()
    local bufnr = vim.api.nvim_get_current_buf()
    local conflicts = scan_conflicts()
    state.conflicts[bufnr] = conflicts

    if #conflicts > 0 then
        highlight_conflicts(conflicts)
        if config.default_keymaps then
            setup_buffer_keymaps(bufnr)
        end
        setup_matchit(bufnr)
        vim.notify(string.format("Found %d conflict(s) that need to be resolved", #conflicts), vim.log.levels.INFO)

        if config.on_conflict_detected then
            pcall(config.on_conflict_detected, { bufnr = bufnr, conflicts = conflicts })
        end
    else
        local ns_id = state.namespace or vim.api.nvim_create_namespace("resolve_conflicts")
        vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
        if config.default_keymaps then
            remove_buffer_keymaps(bufnr)
        end
        remove_matchit(bufnr)

        if config.on_conflicts_resolved then
            pcall(config.on_conflicts_resolved, { bufnr = bufnr })
        end
    end

    return conflicts
end

--- Navigate
function M.next_conflict()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local cursor = vim.api.nvim_win_get_cursor(0)[1]

    for i = cursor + 1, #lines do
        if lines[i]:match(config.markers.ours) then
            vim.api.nvim_win_set_cursor(0, { i, 0 })
            return
        end
    end
    vim.notify("No more conflicts", vim.log.levels.INFO)
end

function M.prev_conflict()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local cursor = vim.api.nvim_win_get_cursor(0)[1]

    for i = cursor - 1, 1, -1 do
        if lines[i]:match(config.markers.ours) then
            vim.api.nvim_win_set_cursor(0, { i, 0 })
            return
        end
    end
    vim.notify("No previous conflicts", vim.log.levels.INFO)
end

--- Resolve functions
function M.choose_ours()
    local c = get_current_conflict()
    if not c then
        vim.notify("Not in a conflict", vim.log.levels.WARN)
        return
    end
    local end_line = c.ancestor and (c.ancestor - 1) or (c.separator - 1)
    local lines = vim.api.nvim_buf_get_lines(0, c.ours_start, end_line, false)
    vim.api.nvim_buf_set_lines(0, c.start - 1, c["end"], false, lines)
    M.detect_conflicts()
end

function M.choose_theirs()
    local c = get_current_conflict()
    if not c then
        vim.notify("Not in a conflict", vim.log.levels.WARN)
        return
    end
    local lines = vim.api.nvim_buf_get_lines(0, c.separator, c.theirs_end - 1, false)
    vim.api.nvim_buf_set_lines(0, c.start - 1, c["end"], false, lines)
    M.detect_conflicts()
end

function M.choose_both()
    local c = get_current_conflict()
    if not c then
        vim.notify("Not in a conflict", vim.log.levels.WARN)
        return
    end
    local ours_end = c.ancestor and (c.ancestor - 1) or (c.separator - 1)
    local ours = vim.api.nvim_buf_get_lines(0, c.ours_start, ours_end, false)
    local theirs = vim.api.nvim_buf_get_lines(0, c.separator, c.theirs_end - 1, false)
    vim.api.nvim_buf_set_lines(0, c.start - 1, c["end"], false, vim.list_extend(ours, theirs))
    M.detect_conflicts()
end

function M.choose_both_reverse()
    local c = get_current_conflict()
    if not c then
        vim.notify("Not in a conflict", vim.log.levels.WARN)
        return
    end
    local ours_end = c.ancestor and (c.ancestor - 1) or (c.separator - 1)
    local ours = vim.api.nvim_buf_get_lines(0, c.ours_start, ours_end, false)
    local theirs = vim.api.nvim_buf_get_lines(0, c.separator, c.theirs_end - 1, false)
    vim.api.nvim_buf_set_lines(0, c.start - 1, c["end"], false, vim.list_extend(theirs, ours))
    M.detect_conflicts()
end

function M.choose_none()
    local c = get_current_conflict()
    if not c then
        vim.notify("Not in a conflict", vim.log.levels.WARN)
        return
    end
    vim.api.nvim_buf_set_lines(0, c.start - 1, c["end"], false, {})
    M.detect_conflicts()
end

function M.choose_base()
    local c = get_current_conflict()
    if not c or not c.ancestor then
        vim.notify("Not in a diff3 conflict", vim.log.levels.WARN)
        return
    end
    local lines = vim.api.nvim_buf_get_lines(0, c.ancestor, c.separator - 1, false)
    vim.api.nvim_buf_set_lines(0, c.start - 1, c["end"], false, lines)
    M.detect_conflicts()
end

--- List conflicts
function M.list_conflicts()
    local conflicts = scan_conflicts()
    if #conflicts == 0 then
        vim.notify("No conflicts", vim.log.levels.INFO)
        return
    end

    local qf = {}
    local bufnr = vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(bufnr)

    for i, c in ipairs(conflicts) do
        table.insert(qf,
            { bufnr = bufnr, filename = file, lnum = c.start, text = string.format("Conflict %d/%d", i, #conflicts) })
    end

    vim.fn.setqflist(qf)
    vim.cmd("copen")
end

--- Setup
function M.setup(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})
    setup_highlights()
    setup_plug_mappings()

    local ag = vim.api.nvim_create_augroup("ResolveConflicts", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", { group = ag, pattern = "*", callback = setup_highlights })
    vim.api.nvim_create_autocmd({ "BufRead", "BufEnter", "FileChangedShellPost" }, {
        group = ag,
        pattern = "*",
        callback = function()
            M.detect_conflicts()
        end,
    })

    state.augroup = ag
end

return M
