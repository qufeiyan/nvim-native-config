--[[
Integration test: verify augroup deletion suppresses "Terminal exited" notification.

This tests the mechanism used by close_term() in terminal.lua:
  nvim_get_autocmds({ event = "TermClose", buffer = buf }) ->
  nvim_del_augroup_by_id(ac.group)

Without this, nvim_clear_autocmds({ event, buffer }) alone cannot remove
autocmds registered with a group (augroup), which is how snacks registers them.

Run: nvim --headless -c "luafile tests/test_augroup_delete.lua" -c "qa"
]]

local failures = {}

local function assert_eq(got, expected, msg)
    if got ~= expected then
        error(string.format("FAIL: %s (expected %s, got %s)", msg or "", vim.inspect(expected), vim.inspect(got)))
    end
end

local function assert_truthy(v, msg)
    if not v then
        error(string.format("FAIL: %s (expected truthy, got %s)", msg or "", vim.inspect(v)))
    end
end

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        print("  PASS: " .. name)
    else
        print("  FAIL: " .. name .. ": " .. tostring(err))
        table.insert(failures, name .. ": " .. tostring(err))
    end
end

local function suite(name)
    print("\n=== " .. name .. " ===\n")
end

-- ============================================================
suite("Augroup Deletion for TermClose Suppression")

test("clear_autocmds(event,buffer) does NOT remove group-registered autocmds", function()
    local buf = vim.api.nvim_create_buf(false, true)
    local augroup = vim.api.nvim_create_augroup("int_test_1", { clear = true })

    -- Register like snacks does: with group AND buffer
    local handler_fired = false
    vim.api.nvim_create_autocmd("BufWipeout", {
        group = augroup,
        buffer = buf,
        callback = function()
            handler_fired = true
        end,
    })

    -- Try clear_autocmds (our original broken fix)
    vim.api.nvim_clear_autocmds({ event = "BufWipeout", buffer = buf })

    -- This should fail — handler still fires because it's in an augroup
    vim.api.nvim_buf_delete(buf, { force = true })

    assert_eq(handler_fired, true, "handler should fire (autocmd survives clear_autocmds)")
end)

test("delete augroup before buf_delete suppresses handler", function()
    local buf = vim.api.nvim_create_buf(false, true)
    local augroup = vim.api.nvim_create_augroup("int_test_2", { clear = true })

    local handler_fired = false
    vim.api.nvim_create_autocmd("BufWipeout", {
        group = augroup,
        buffer = buf,
        callback = function()
            handler_fired = true
        end,
    })

    -- Find and delete augroup (our fix)
    local autocmds = vim.api.nvim_get_autocmds({ event = "BufWipeout", buffer = buf })
    assert_truthy(#autocmds > 0, "should find autocmds before deletion")

    local seen = {}
    for _, ac in ipairs(autocmds) do
        if ac.group and not seen[ac.group] then
            seen[ac.group] = true
            vim.api.nvim_del_augroup_by_id(ac.group)
        end
    end

    -- Now delete buffer — handler should NOT fire
    vim.api.nvim_buf_delete(buf, { force = true })

    assert_eq(handler_fired, false, "handler should NOT fire after augroup deletion")
end)

test("TermClose autocmds can be found and removed by buffer", function()
    local buf = vim.api.nvim_create_buf(false, true)
    local augroup = vim.api.nvim_create_augroup("int_test_3", { clear = true })

    -- Register like snacks' auto_close does
    local fired = false
    vim.api.nvim_create_autocmd("TermClose", {
        group = augroup,
        buffer = buf,
        callback = function()
            fired = true
        end,
    })

    -- Find TermClose autocmds for this buffer
    local autocmds = vim.api.nvim_get_autocmds({ event = "TermClose", buffer = buf })
    assert_truthy(#autocmds > 0, "should find TermClose autocmds by buffer+event")

    -- Delete the augroup
    local seen = {}
    for _, ac in ipairs(autocmds) do
        if ac.group and not seen[ac.group] then
            seen[ac.group] = true
            vim.api.nvim_del_augroup_by_id(ac.group)
        end
    end

    -- Verify autocmds are gone
    autocmds = vim.api.nvim_get_autocmds({ event = "TermClose", buffer = buf })
    assert_eq(#autocmds, 0, "all TermClose autocmds should be removed")

    vim.api.nvim_buf_delete(buf, { force = true })
    print("  PASS: (sub-check) TermClose autocmds found and removed by buffer")
end)

-- ============================================================
local n_failed = #failures
print(string.format("\n%s %d passed, %d failed",
    n_failed == 0 and "All tests passed:" or "Results:", 3 - n_failed, n_failed))

if n_failed > 0 then
    vim.cmd("cq")
end
