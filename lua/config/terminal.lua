---@class config.terminal
---VS Code-style multi-terminal manager built on snacks.nvim terminal API.
---
---  - Terminals are numbered 1..N, distinguished via `opts.count`.
---  - `active` tracks the last visible terminal (bottom or float).
---  - `<C-t>h/l` cycles through ALL terminals (bottom + float), so you can
---    switch from a float to a bottom terminal and vice versa.
---  - `toggle()` hides everything; pressing again restores the last bottom terminal.
local M = {}

---@type snacks.win? currently visible terminal (bottom or float)
local active = nil

---Last active terminal id (count), restored by toggle() / <C-S-;>. Defaults to 1.
local last_active_id = 1

---Get a terminal by index. Returns nil if it does not exist or is dead.
---@param index integer
---@return snacks.win?
local function get(index)
    local term = require("snacks").terminal.get(nil, { count = index, create = false })
    if term and term:buf_valid() then
        return term
    end
end

---List all valid terminals.
---Sorted: bottom terminals first (by count), then floats (by count).
---@return snacks.win[]
local function list_all()
    local all = require("snacks").terminal.list()
    local bottoms, floats = {}, {}
    for _, t in ipairs(all) do
        if t:buf_valid() then
            if t:is_floating() then
                floats[#floats + 1] = t
            else
                bottoms[#bottoms + 1] = t
            end
        end
    end
    local function by_id(a, b)
        local ia = (vim.b[a.buf].snacks_terminal or {}).id or 0
        local ib = (vim.b[b.buf].snacks_terminal or {}).id or 0
        return ia < ib
    end
    table.sort(bottoms, by_id)
    table.sort(floats, by_id)
    for _, f in ipairs(floats) do
        bottoms[#bottoms + 1] = f
    end
    return bottoms
end

---Find the first free terminal index (1..N).
---@return integer
local function first_free()
    local used = {}
    for _, t in ipairs(require("snacks").terminal.list()) do
        local info = vim.b[t.buf].snacks_terminal
        if info and info.id then
            used[info.id] = true
        end
    end
    for i = 1, 99 do
        if not used[i] then
            return i
        end
    end
    return 1
end

---Hide a terminal window cleanly.
local function hide(term)
    if term and term:buf_valid() and term:win_valid() then
        term:hide()
    end
end

---Show and focus a terminal. Returns the terminal.
local function show(term)
    term:show()
    term:focus()
    M.setup_buf_keymaps(term.buf)
    return term
end

---Close the given terminal and clean up tracking.
---Finds and deletes the snacks augroup (which owns the TermClose autocmd)
---before deleting the buffer, so the "Terminal exited with code -1" handler
---cannot fire.  nvim_clear_autocmds(event, buffer) does NOT remove
---autocmds registered with a group, so we must delete the augroup itself.
---@param term snacks.win
local function close_term(term)
    if active == term then
        active = nil
    end
    if term:buf_valid() then
        local buf = term.buf
        vim.b[buf].snacks_terminal = nil
        -- Delete the snacks augroup owning the TermClose autocmd for this buf.
        -- nvim_clear_autocmds({ event, buffer }) does NOT remove autocmds
        -- registered with a group (augroup), so this is the only way.
        local autocmds = vim.api.nvim_get_autocmds({ event = "TermClose", buffer = buf })
        local seen = {}
        for _, ac in ipairs(autocmds) do
            if ac.group and not seen[ac.group] then
                seen[ac.group] = true
                pcall(vim.api.nvim_del_augroup_by_id, ac.group)
            end
        end
    end
    term:close({ buf = true })
end

---Get the count-id of a terminal.
local function tid_of(term)
    local info = vim.b[term.buf].snacks_terminal or {}
    return info.id or 1
end

---Toggle terminal panel.
---If any terminal is visible → hide all of them.
---If none are visible → restore the last active terminal.
function M.toggle()
    local all = list_all()
    local any_visible = false
    for _, t in ipairs(all) do
        if t:win_valid() then
            any_visible = true
            t:hide()
        end
    end
    active = nil

    if any_visible then
        return
    end

    -- Restore the last bottom terminal.
    local index = vim.v.count1 > 1 and vim.v.count1 or last_active_id
    local term = get(index)
    if not term or term:is_floating() then
        -- Fall back to the first valid bottom terminal
        index = 1
        for _, t in ipairs(all) do
            if not t:is_floating() then
                index = tid_of(t)
                break
            end
        end
    end
    M.switch(index)
end

---Toggle the active terminal between "bottom" and "float" position.
---Preserves the terminal process, buffer, and visibility state.
function M.toggle_position()
    if not active or not active:buf_valid() then
        return
    end

    local term = active
    local was_visible = term:win_valid()
    local new_pos = term:is_floating() and "bottom" or "float"

    -- Hide the window but keep the buffer alive
    if was_visible then
        term:hide()
    end

    -- Swap position + adjust opts for the new type
    if new_pos == "float" then
        -- Don't set row/col — nil centers the window
        term.opts.relative = "editor"
        term.opts.zindex = 50
        term.opts.border = "rounded"
        term.opts.height = 0.8
        term.opts.width = 0.8
        term.opts.row = nil
        term.opts.col = nil
    else
        term.opts.border = "none"
        term.opts.zindex = nil
        term.opts.height = 0.3
        term.opts.width = nil
        term.opts.row = nil
        term.opts.col = nil
    end
    term.opts.position = new_pos

    if was_visible then
        term:show()
        term:focus()
        M.setup_buf_keymaps(term.buf)
    end
end

---Create a new bottom terminal with the next free index.
function M.create()
    local index = first_free()
    hide(active)
    local term = require("snacks").terminal.open(nil, {
        count = index,
        cwd = vim.fn.getcwd(0),
        interactive = true,
        win = { position = "bottom" },
    })
    active = term
    last_active_id = index
    show(term)
end

---Switch to terminal {index}. Creates a bottom terminal if needed.
---@param index? integer (defaults to vim.v.count1)
function M.switch(index)
    index = index or vim.v.count1
    local term = get(index)

    if not term then
        hide(active)
        local created = require("snacks").terminal.open(nil, {
            count = index,
            cwd = vim.fn.getcwd(0),
            interactive = true,
            win = { position = "bottom" },
        })
        active = created
        last_active_id = index
        show(created)
        return
    end

    -- If target is already visible, just focus it.
    if term:win_valid() and active and term.buf == active.buf then
        term:focus()
        return
    end

    hide(active)
    active = term
    last_active_id = index
    show(term)
end

---Find the index of {term} in the all-terminal list.
local function list_index(term, list)
    for i, t in ipairs(list) do
        if t.buf == term.buf then
            return i
        end
    end
    return -1
end

---Switch to the next terminal (bottom or float, wrap-around).
function M.switch_next()
    local list = list_all()
    if #list == 0 then
        M.create()
        return
    end
    local cur = active and list_index(active, list) or -1
    local next_i = cur == -1 and 1 or (cur % #list) + 1
    hide(active)
    active = list[next_i]
    last_active_id = tid_of(active)
    show(active)
end

---Switch to the previous terminal (bottom or float, wrap-around).
function M.switch_prev()
    local list = list_all()
    if #list == 0 then
        M.create()
        return
    end
    local cur = active and list_index(active, list) or -1
    local prev_i = cur == -1 and 1 or ((cur - 2) % #list) + 1
    hide(active)
    active = list[prev_i]
    last_active_id = tid_of(active)
    show(active)
end

---Delete (kill) a terminal by index.
---When called from a keymap without a prefix count (vim.v.count == 0),
---defaults to the active terminal.  With an explicit count prefix or a
---programmatic argument, deletes that specific terminal.
---After deleting the active visible terminal, switches focus to the next
---valid bottom terminal.  Also cleans up last_active_id if it pointed to
---the deleted terminal.
---@param index? integer (defaults to active, then vim.v.count1)
function M.delete(index)
    if index == nil then
        if vim.v.count > 0 then
            index = vim.v.count1
        elseif active then
            index = tid_of(active)
        else
            index = vim.v.count1
        end
    end
    local term = get(index)
    if not term then
        return
    end

    local was_active = (active == term)
    local was_visible = term:win_valid()

    -- Update last_active_id if it pointed to the soon-to-be-deleted terminal
    if last_active_id == index then
        local all = list_all()
        local found = false
        for _, t in ipairs(all) do
            if t ~= term and tid_of(t) ~= index then
                last_active_id = tid_of(t)
                found = true
                break
            end
        end
        if not found then
            last_active_id = 1
        end
    end

    close_term(term)

    -- If the deleted terminal was active and visible, switch to another
    if was_active and was_visible then
        local all = list_all()
        if #all > 0 then
            local target = nil
            for _, t in ipairs(all) do
                if not t:is_floating() then
                    target = t
                    break
                end
            end
            if not target then
                target = all[1]
            end
            active = target
            last_active_id = tid_of(target)
            show(target)
        end
    end
end

---Pick a terminal from a list (uses vim.ui.select).
function M.pick()
    local all = require("snacks").terminal.list()
    if #all == 0 then
        vim.notify("No active terminals", vim.log.levels.INFO)
        return
    end

    local items = {}
    for _, t in ipairs(all) do
        local info = vim.b[t.buf].snacks_terminal or {}
        local label = string.format("%s [%d]", t:is_floating() and "⿿ float" or "▁ terminal", info.id or "?")
        local details = {}
        if info.cwd then
            details[#details + 1] = info.cwd
        end
        if info.cmd then
            local cmd_str = type(info.cmd) == "table" and table.concat(info.cmd, " ") or info.cmd
            if #cmd_str > 0 then
                details[#details + 1] = cmd_str
            end
        end
        items[#items + 1] = {
            term = t,
            label = label,
            id = info.id,
            details = table.concat(details, " | "),
        }
    end

    vim.ui.select(items, {
        prompt = "Terminals:",
        format_item = function(item)
            if item.details and #item.details > 0 then
                return string.format("%s  (%s)", item.label, item.details)
            end
            return item.label
        end,
    }, function(choice)
        if not choice then
            return
        end
        -- Hide previous active before showing the chosen one.
        hide(active)
        active = choice.term
        last_active_id = choice.id or 1
        show(choice.term)
    end)
end

---Set up buffer-local keymaps for a terminal window.
function M.setup_buf_keymaps(buf)
    vim.keymap.set("n", "<C-w>h", M.switch_prev, { buffer = buf, desc = "Previous terminal" })
    vim.keymap.set("n", "<C-w>l", M.switch_next, { buffer = buf, desc = "Next terminal" })
end

---Setup terminal global keymaps and autocommands. Call once from init.lua.
function M.setup()
    -- Helper: stopinsert before running action if called from terminal mode
    local function t(fn)
        return function()
            if vim.fn.mode() == "t" then
                vim.cmd.stopinsert()
            end
            fn()
        end
    end

    -- Normal mode: <leader>t prefix
    vim.keymap.set("n", "<leader>`", M.toggle, { desc = "Toggle terminal" })
    vim.keymap.set("n", "<leader>tt", M.toggle, { desc = "Toggle terminal" })
    vim.keymap.set("n", "<leader>tn", M.create, { desc = "New terminal" })
    vim.keymap.set("n", "<leader>tr", M.toggle_position, { desc = "Toggle terminal position" })
    vim.keymap.set("n", "<leader>th", M.switch_prev, { desc = "Previous terminal" })
    vim.keymap.set("n", "<leader>tl", M.switch_next, { desc = "Next terminal" })
    vim.keymap.set("n", "<leader>td", M.delete, { desc = "Delete terminal" })
    vim.keymap.set("n", "<leader>tp", M.pick, { desc = "Pick terminal" })
    for i = 1, 9 do
        local idx = i
        vim.keymap.set("n", "<leader>t" .. idx, function()
            M.switch(idx)
        end, { desc = "Terminal " .. idx })
    end

    -- Terminal mode: <C-;> quick toggle
    vim.keymap.set({ "n", "t" }, "<C-S-;>", t(M.toggle), { desc = "Toggle terminal" })

    -- Terminal mode: <C-t> prefix
    vim.keymap.set("t", "<C-t>t", t(M.toggle), { desc = "Toggle terminal" })
    vim.keymap.set("t", "<C-t>n", t(M.create), { desc = "New terminal" })
    vim.keymap.set("t", "<C-t>r", t(M.toggle_position), { desc = "Toggle terminal position" })
    vim.keymap.set("t", "<C-t>h", t(M.switch_prev), { desc = "Previous terminal" })
    vim.keymap.set("t", "<C-t>l", t(M.switch_next), { desc = "Next terminal" })
    vim.keymap.set("t", "<C-t>d", t(M.delete), { desc = "Delete terminal" })
    vim.keymap.set("t", "<C-t>p", t(M.pick), { desc = "Pick terminal" })
    for i = 1, 9 do
        local idx = i
        vim.keymap.set(
            "t",
            "<C-t>" .. idx,
            t(function()
                M.switch(idx)
            end),
            { desc = "Terminal " .. idx }
        )
    end
end

return M
