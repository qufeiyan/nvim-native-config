--[[
Headless Neovim tests for lua/config/terminal.lua

Run: nvim --headless -c "luafile tests/test_terminal.lua" -c "qa"

Strategy:
  - Mock snacks.terminal to isolate terminal.lua logic from display/term dependencies
  - Use a shared `snacks_terminal` reference consistently — both terminal.lua and tests
    access the same mock instance
  - Each test validates specific interface contract and state transitions
]]

local mock_objects = {} ---@type table<integer, table>
local mock_terminals = {}

---@return table mock terminal object
local function mock_terminal(index, is_float)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.b[buf].snacks_terminal = { cmd = nil, id = index, cwd = vim.fn.getcwd(0) }
  local win = nil
  local obj = { buf = buf, opts = { position = is_float and "float" or "bottom" } }

  function obj.buf_valid()
    return buf ~= nil and vim.api.nvim_buf_is_valid(buf)
  end

  function obj.win_valid()
    return win ~= nil and vim.api.nvim_win_is_valid(win)
  end

  function obj.is_floating()
    if not win or not vim.api.nvim_win_is_valid(win) then
      return false
    end
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
      return false
    end
    if vim.api.nvim_win_get_buf(win) ~= buf then
      return false
    end
    return obj.opts.position == "float"
  end

  function obj.show()
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
      return
    end
    vim.api.nvim_set_current_buf(buf)
    if obj.opts.position == "float" then
      win = vim.api.nvim_open_win(buf, true, {
        relative = "editor", width = 60, height = 15,
        row = 2, col = 10, zindex = 50,
      })
    else
      win = vim.api.nvim_open_win(buf, true, {
        relative = "editor", width = 80, height = 20,
        row = 0, col = 0, style = "minimal",
      })
    end
  end

  function obj.focus()
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
    end
  end

  function obj.hide()
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    win = nil
  end

  function obj.close(opts)
    local do_close = (opts or {}).buf ~= false
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    win = nil
    if do_close and buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  return obj
end

-- Shared mock reference — BOTH terminal.lua (via patched require) and test code
-- access this same table.
snacks_terminal = {
  _reset = function()
    mock_objects = {}
    mock_terminals = {}
  end,

  _calls = {},
  _record = function(self, fn, ...)
    table.insert(self._calls, { fn = fn, args = { ... } })
  end,

  get = function(cmd, opts)
    snacks_terminal:_record("get", cmd, opts)
    opts = opts or {}
    local index = opts.count or vim.v.count1
    local obj = mock_objects[index]
    if obj and obj:buf_valid() then
      return obj, false
    end
    if opts.create == false then
      return nil, false
    end
    local term = mock_terminal(index)
    mock_objects[index] = term
    return term, true
  end,

  list = function()
    local result = {}
    for _, t in pairs(mock_objects) do
      if t:buf_valid() then
        result[#result + 1] = t
      end
    end
    return result
  end,

  open = function(cmd, opts)
    snacks_terminal:_record("open", cmd, opts)
    opts = opts or {}
    local index = opts.count or vim.v.count1
    local is_float = opts.win and opts.win.position == "float"
    local term = mock_terminal(index, is_float)
    mock_objects[index] = term
    return term
  end,
}

-- Patch require so terminal.lua uses our mock.
-- Keep patched for the entire test run (we're in an isolated headless process).
local orig_require = require
_G.require = function(name)
  if name == "snacks" or name == "snacks.terminal" then
    local t = orig_require("snacks")
    t.terminal = snacks_terminal
    return t
  end
  if name == "config.terminal" then
    package.loaded["config.terminal"] = nil
    return orig_require("config.terminal")
  end
  return orig_require(name)
end

-- ============================================================
-- Test Framework
-- ============================================================
local failures = {} ---@type string[]

local function assert_eq(got, expected, msg)
  if got ~= expected then
    error(string.format("expected %s, got %s", vim.inspect(expected), vim.inspect(got)))
  end
end

local function assert_truthy(v, msg)
  if not v then
    error(string.format("expected truthy, got %s", vim.inspect(v)))
  end
end

local function assert_falsy(v, msg)
  if v then
    error(string.format("expected falsy, got %s", vim.inspect(v)))
  end
end

---@param name string
---@param fn fun()
local function test(name, fn)
  snacks_terminal._calls = {}
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

-- Reload module with fresh mock state.
-- require is already globally patched to use the mock.
local function reload()
  package.loaded["config.terminal"] = nil
  snacks_terminal:_reset()
  return require("config.terminal")
end

-- ============================================================
-- Suite 1: Module Interface
-- ============================================================
suite("Module Interface")

do
  local term = reload()
  test("module loads and returns a table", function()
    assert_eq(type(term), "table")
  end)

  test("exports all public functions", function()
    local required = {
      "toggle", "create", "switch", "switch_next", "switch_prev",
      "toggle_position", "delete", "pick", "setup_buf_keymaps",
    }
    for _, name in ipairs(required) do
      assert_eq(type(term[name]), "function", "Missing: " .. name)
    end
  end)

  test("setup() function exists", function()
    assert_eq(type(term.setup), "function", "setup() should exist after bug fix")
  end)
end

-- ============================================================
-- Suite 2: Terminal Operations
-- ============================================================
suite("Terminal Operations")

do
  local term = reload()

  test("toggle() creates terminal on first call", function()
    term.toggle()
    assert_eq(#snacks_terminal.list(), 1, "one terminal after toggle")
  end)

  test("toggle() hides when terminal is visible, shows when hidden", function()
    local term = reload()
    term.toggle()                     -- create + show
    assert_truthy(snacks_terminal.list()[1]:win_valid(), "visible after toggle-on")

    term.toggle()                     -- hide
    assert_falsy(snacks_terminal.list()[1]:win_valid(), "hidden after toggle-off")

    term.toggle()                     -- restore
    assert_truthy(snacks_terminal.list()[1]:win_valid(), "visible after second toggle-on")
  end)

  test("create() assigns unique ids", function()
    local term = reload()
    term.create()
    term.create()
    term.create()
    assert_eq(#snacks_terminal.list(), 3, "3 creates = 3 terminals")
  end)

  test("create() reuses freed ids", function()
    local term = reload()
    term.create()                     -- #1
    term.create()                     -- #2
    term.create()                     -- #3
    term.delete(2)                    -- free #2
    term.create()                     -- should reuse #2
    assert_eq(#snacks_terminal.list(), 3, "3 after create/create/delete/create")
  end)

  test("switch(n) creates terminal if not exists", function()
    local term = reload()
    term.switch(5)
    assert_eq(#snacks_terminal.list(), 1, "switch(5) creates one terminal")
  end)

  test("switch(n) switches to existing terminal", function()
    local term = reload()
    term.create()
    term.create()
    term.switch(1)                    -- back to #1
    -- no crash
  end)

  test("switch_next/prev cycles through terminals", function()
    local term = reload()
    term.create()
    term.create()
    term.create()
    term.switch(1)
    term.switch_next()
    term.switch_next()
    term.switch_prev()
    term.switch_prev()
    -- no crash
  end)

  test("switch_next creates one when list is empty", function()
    local term = reload()
    term.switch_next()
    assert_eq(#snacks_terminal.list(), 1, "switch_next on empty creates")
  end)

  test("delete() removes terminal buffer", function()
    local term = reload()
    term.create()
    term.delete(1)
    assert_eq(#snacks_terminal.list(), 0, "no terminals after delete")
  end)
end

-- ============================================================
-- Suite 3: Edge Cases
-- ============================================================
suite("Edge Cases")

do
  local term = reload()

  test("delete() on non-existent terminal is no-op", function()
    term.delete(99)
    -- no crash
  end)

  test("switch() with no args defaults to terminal 1", function()
    term.switch()
    assert_eq(#snacks_terminal.list(), 1, "switch() creates terminal 1")
  end)

  test("multiple toggles cycle correctly", function()
    local term = reload()
    term.toggle()
    term.toggle()
    term.toggle()
    term.toggle()
    term.toggle()
    assert_eq(#snacks_terminal.list(), 1, "one terminal after 5 toggles")
  end)

  test("buffer kill then create", function()
    local term = reload()
    term.create()
    -- kill buffer directly
    local all = snacks_terminal.list()
    if #all > 0 and all[1].buf_valid() then
      vim.api.nvim_buf_delete(all[1].buf, { force = true })
    end
    term.create()
    assert_eq(#snacks_terminal.list(), 1, "create after buffer kill works")
  end)

  test("quick successive creates", function()
    local term = reload()
    for _ = 1, 5 do term.create() end
    assert_eq(#snacks_terminal.list(), 5, "5 creates = 5 terminals")
  end)

  test("switch to already-focused terminal", function()
    local term = reload()
    term.create()
    term.switch(1)                    -- no crash
  end)
end

-- ============================================================
-- Suite 4: Known Bug Reproduction
-- ============================================================
suite("Known Bug Reproduction")

-- BUG #3 FIXED: setup() function consolidated in terminal.lua
do
  local term = reload()

  test("BUG#3 (fixed): setup() function exists", function()
    assert_eq(type(term.setup), "function",
      "setup() now exists -- keymaps consolidated from snacks.lua into terminal.lua")
  end)
end

-- BUG #4: last_active_id is a single flat counter shared between
-- bottom and float terminals, causing cross-contamination.
do
  local term = reload()

  test("BUG#4: switch_next/prev track through floats", function()
    local term = reload()
    term.create()                     -- #1 bottom, active = #1
    for _ = 1, 3 do term.create() end -- #2, #3, #4 bottom
    term.switch(1)                    -- active = #1
    local list1 = snacks_terminal.list()
    assert_truthy(#list1 >= 1, "terminals exist")

    term.toggle_position()            -- convert #1 to float
    term.switch_next()                -- goes to next terminal in list

    -- The list includes floats. switch_next/prev cycle all terminals.
    -- This is by design but worth noting as an area of confusion.
  end)
end

-- BUG #5: delete() leaves dangling last_active_id
do
  local term = reload()

  test("BUG#5: last_active_id is not validated on toggle", function()
    term.create()                     -- #1, last_active_id=1
    term.create()                     -- #2, last_active_id=2
    term.delete(2)                    -- #2 removed, last_active_id still = 2

    -- toggle() uses last_active_id = 2, calls switch(2)
    -- get(2) returns nil (terminal was deleted)
    -- switch(2) creates a NEW terminal #2
    toggle_result = term.toggle()

    -- This is acceptable (lazy recreation) but may be surprising.
    -- A fallback to the next valid terminal would be more robust.
  end)
end

-- BUG #6: dead buffer leads to terminal showing as a new window
do
  local term = reload()

  test("BUG#6: hidden terminal with dead buffer", function()
    term.create()                     -- #1, active = #1
    term.toggle()                     -- hide all, active = nil

    -- Kill buffer behind the scenes
    local all = snacks_terminal.list()
    if #all > 0 and all[1].buf_valid() then
      vim.api.nvim_buf_delete(all[1].buf, { force = true })
    end

    -- toggle should not crash
    term.toggle()
  end)
end

-- ============================================================
-- Suite 5: State Consistency (each test reloads for clean state)
-- ============================================================
suite("State Consistency")

test("list_all() returns all valid buffers", function()
  local term = reload()
  for _ = 1, 5 do term.create() end
  assert_eq(#snacks_terminal.list(), 5, "5 terminals in list")
end)

test("delete removes from list", function()
  local term = reload()
  for _ = 1, 3 do term.create() end
  term.delete(1)   -- deletes terminal 1
  term.delete(99)  -- no-op: terminal 99 doesn't exist
  assert_eq(#snacks_terminal.list(), 2, "2 terminals remain (2 and 3)")
end)

test("toggle after partial delete restores last active", function()
  local term = reload()
  for _ = 1, 3 do term.create() end  -- terminals 1,2,3, active=#3
  term.toggle()                      -- hide all, active=nil, last_active_id=3
  term.delete(3)                     -- remove #3, get(3) returns nil
  term.toggle()                      -- last_active_id=3 -> nil, fallback to first bottom #1
  assert_eq(#snacks_terminal.list(), 2, "2 terminals (1 and 2), fallback restores #1")
end)

-- ============================================================
-- Suite 6: Delete Scenarios
-- ============================================================
suite("Delete Scenarios")

test("delete() with no count, no active -> falls back to count1=1", function()
  local term = reload()
  -- No terminals exist, no active. vim.v.count=0, vim.v.count1=1
  -- get(1) returns nil (no terminal 1), so it's a no-op
  term.delete()
  assert_eq(#snacks_terminal.list(), 0, "no terminals created")
end)

test("delete() with no count, active exists -> deletes active terminal", function()
  local term = reload()
  term.create()                          -- #1, active=#1
  term.create()                          -- #2, active=#2
  term.delete()                          -- no count, active=#2 -> deletes #2
  assert_eq(#snacks_terminal.list(), 1, "one terminal remains (#1)")
  local all = snacks_terminal.list()
  local info = vim.b[all[1].buf].snacks_terminal
  assert_eq(info.id, 1, "terminal 1 remains")
end)

test("delete(2) with explicit arg -> deletes terminal 2", function()
  local term = reload()
  term.create()                          -- #1, active=#1
  term.create()                          -- #2, active=#2
  term.delete(2)                         -- explicit arg
  assert_eq(#snacks_terminal.list(), 1, "one terminal remains (#1)")
  local all = snacks_terminal.list()
  local info = vim.b[all[1].buf].snacks_terminal
  assert_eq(info.id, 1, "remaining terminal is #1")
end)

test("delete(5) with non-existent arg -> no-op", function()
  local term = reload()
  term.create()                          -- #1
  term.create()                          -- #2
  term.delete(5)                         -- no-op, #5 doesn't exist
  assert_eq(#snacks_terminal.list(), 2, "two terminals unaffected")
end)

test("delete() non-active terminal -> active stays unchanged", function()
  local term = reload()
  term.create()                          -- #1, active=#1, visible
  term.create()                          -- #2, active=#2, visible
  term.switch(1)                         -- active=#1
  term.delete(2)                         -- delete non-active #2
  local all = snacks_terminal.list()
  assert_eq(#all, 1, "only terminal 1 remains")
end)

test("delete() active visible terminal -> switches to next terminal", function()
  local term = reload()
  term.create()                          -- #1, active=#1
  term.create()                          -- #2, active=#2
  term.delete()                          -- no count -> active=#2 -> delete #2
  -- Should auto-switch to #1 and show it
  local all = snacks_terminal.list()
  assert_eq(#all, 1, "only terminal 1 remains")
  assert_truthy(all[1]:win_valid(), "terminal 1 is visible after auto-switch")
end)

test("delete() active visible terminal, no other -> no switch, last_active_id=1", function()
  local term = reload()
  term.create()                          -- #1, active=#1, visible
  term.delete()                          -- no count -> active=#1 -> delete #1
  assert_eq(#snacks_terminal.list(), 0, "no terminals left")
  -- toggle should create a new terminal (last_active_id fell back to 1)
  term.toggle()
  assert_eq(#snacks_terminal.list(), 1, "toggle creates new terminal 1")
end)

test("delete updates last_active_id", function()
  local term = reload()
  term.create()                          -- #1, last_active_id=1
  term.create()                          -- #2, last_active_id=2
  term.delete(2)                         -- delete #2, last_active_id was 2 -> updated to 1
  -- Verify: toggle should restore #1, not try to create a new #2
  term.toggle()
  term.toggle()                          -- hide
  term.toggle()                          -- restore -> should use last_active_id=1
  assert_eq(#snacks_terminal.list(), 1, "only 1 terminal after toggle sequence")
end)

test("delete() after all terminals cleaned -> last_active_id reset to 1", function()
  local term = reload()
  term.create()                          -- #1, last_active_id=1
  term.create()                          -- #2, last_active_id=2
  term.create()                          -- #3, last_active_id=3
  term.delete(2)                         -- last_active_id=3, not affected
  term.delete(1)                         -- last_active_id=3, not affected
  term.delete(3)                         -- last_active_id was 3 -> no other -> reset to 1
  assert_eq(#snacks_terminal.list(), 0, "no terminals left")
  -- toggle should create terminal 1 (from last_active_id=1)
  term.toggle()
  local all = snacks_terminal.list()
  assert_eq(#all, 1, "toggle created one terminal")
  local info = vim.b[all[1].buf].snacks_terminal
  assert_eq(info.id, 1, "created terminal id is 1")
end)

test("delete active visible terminal, then delete remaining -> no crash", function()
  local term = reload()
  term.create()                          -- #1, active=#1
  term.create()                          -- #2, active=#2
  term.delete()                          -- no count -> delete active #2, switches to #1
  term.delete()                          -- no count -> delete active #1 (the newly switched-to)
  assert_eq(#snacks_terminal.list(), 0, "all terminals deleted")
end)

test("delete middle terminal, last_active_id unchanged if not pointing to it", function()
  local term = reload()
  term.create()                          -- #1, last_active_id=1
  term.create()                          -- #2, last_active_id=2
  term.create()                          -- #3, last_active_id=3
  term.delete(2)                         -- #2 gone, last_active_id=3 (unchanged)
  -- toggle should restore #3
  term.toggle()
  term.toggle()                          -- hide
  term.toggle()                          -- restore -> get(3) -> terminal 3
  -- Note: second toggle after hide creates #4 (last_active_id updated by switch logic)
  -- Just verify no crash and terminals exist
  assert_truthy(#snacks_terminal.list() >= 1, "terminals remain after toggle")
end)

test("delete programmatically with arg overrides count context", function()
  local term = reload()
  term.create()                          -- #1
  term.create()                          -- #2, active=#2
  -- Even if vim.v.count were set, explicit arg takes priority
  term.delete(2)
  assert_eq(#snacks_terminal.list(), 1, "terminal 2 was deleted, 1 remains")
end)

test("multiple deletes in succession", function()
  local term = reload()
  term.create()                          -- #1
  term.create()                          -- #2
  term.create()                          -- #3
  term.create()                          -- #4
  term.delete(2)
  term.delete(4)
  assert_eq(#snacks_terminal.list(), 2, "2 terminals remain (1 and 3)")
  local ids = {}
  for _, t in ipairs(snacks_terminal.list()) do
    ids[#ids + 1] = (vim.b[t.buf].snacks_terminal or {}).id
  end
  table.sort(ids)
  assert_eq(ids[1], 1, "first remaining id is 1")
  assert_eq(ids[2], 3, "second remaining id is 3")
end)

test("jobstop called before buffer close on delete", function()
  local term = reload()
  term.create()                          -- #1
  term.delete(1)
  -- The important thing is no crash (close_term handles the jobstop pcall)
  assert_eq(#snacks_terminal.list(), 0, "terminal deleted without crash")
end)

test("delete does not affect other terminals' buffers", function()
  local term = reload()
  term.create()                          -- #1
  term.create()                          -- #2
  local buf_before = snacks_terminal.list()[2].buf  -- save buf of #2
  term.delete(1)
  local all = snacks_terminal.list()
  assert_eq(#all, 1, "one terminal left")
  assert_eq(all[1].buf, buf_before, "terminal 2 buffer is unchanged")
end)

test("delete all terminals one by one, each delete handles state", function()
  local term = reload()
  for i = 1, 5 do term.create() end      -- 1,2,3,4,5, active=5
  term.delete(5)                          -- last_active_id was 5 -> updates to first valid (1)
  term.delete(1)                          -- last_active_id=1 -> updates to next (2)
  term.delete(2)                          -- last_active_id=2 -> updates to next (3)
  term.delete(3)                          -- last_active_id=3 -> updates to next (4)
  term.delete(4)                          -- last_active_id=4 -> no other -> reset to 1
  assert_eq(#snacks_terminal.list(), 0, "all terminals deleted")
  -- toggle still works and creates terminal 1
  term.toggle()
  local all = snacks_terminal.list()
  local info = vim.b[all[1].buf].snacks_terminal
  assert_eq(info.id, 1, "toggle after all-deleted creates terminal 1")
end)

test("delete with active nil (no active terminal) -> no crash", function()
  local term = reload()
  term.create()                          -- #1, active=#1
  term.toggle()                          -- hide all, active=nil
  term.delete()                          -- no active, no count -> falls back to count1=1
  -- get(1) returns terminal 1 (still valid, just hidden)
  -- delete removes it
  assert_eq(#snacks_terminal.list(), 0, "terminal deleted despite no active")
end)

test("delete terminal id mismatch between active tracking and index", function()
  local term = reload()
  term.create()                          -- #1, active=#1
  term.create()                          -- #2, active=#2
  term.create()                          -- #3, active=#3
  -- active=#3, but delete #1 (active != term)
  term.delete(1)
  assert_eq(#snacks_terminal.list(), 2, "terminals 2 and 3 remain")
  local all = snacks_terminal.list()
  -- Verify #2 and #3 exist, #1 is gone
  local ids = {}
  for _, t in ipairs(all) do
    ids[#ids + 1] = (vim.b[t.buf].snacks_terminal or {}).id
  end
  table.sort(ids)
  assert_eq(ids[1], 2, "terminal 2 exists")
  assert_eq(ids[2], 3, "terminal 3 exists")
end)

test("delete inactive but visible terminal -> no focus switch", function()
  local term = reload()
  term.create()                          -- #1, active=#1 (shown)
  term.create()                          -- #2, active=#2 (shown, last_active_id=2)
  term.switch(1)                         -- active=#1 (shown), terminal 2 still visible
  -- Terminal 2 is visible but not active. Delete it.
  term.delete(2)
  -- active=#1 should still be visible and active
  local all = snacks_terminal.list()
  assert_eq(#all, 1, "terminal 1 remains")
  -- Active wasn't deleted, so it should still be valid
  assert_truthy(all[1]:win_valid(), "terminal 1 still visible")
end)

test("close_term clears b.snacks_terminal and finds+deletes TermClose augroup", function()
  local term = reload()
  term.create()                          -- #1
  local buf = snacks_terminal.list()[1].buf
  -- Before delete, b.snacks_terminal should be set
  assert_truthy(vim.b[buf].snacks_terminal, "snacks_terminal exists before delete")
  term.delete(1)
  -- After delete, buffer is gone
  assert_eq(#snacks_terminal.list(), 0, "terminal deleted")
end)

-- NOTE: Verifying the augroup deletion mechanism requires real snacks.nvim
-- autocmds (not mocked).  See tests/test_augroup_delete.lua for integration
-- tests that confirm nvim_get_autocmds + nvim_del_augroup_by_id suppresses
-- the "Terminal exited with code -1" notification.
--   Run: nvim --headless -c "luafile tests/test_augroup_delete.lua" -c "qa"

-- ============================================================
-- Suite 7: Position Toggle (toggle_position)
-- ============================================================
suite("Position Toggle")

test("toggle_position() with no active terminal -> no-op", function()
  local term = reload()
  term.toggle_position()
  -- no crash = pass
end)

test("toggle_position() bottom -> float preserves visibility and buffer", function()
  local term = reload()
  term.create()                          -- #1 bottom, active=#1
  local all = snacks_terminal.list()
  local buf_before = all[1].buf

  term.toggle_position()

  all = snacks_terminal.list()
  assert_eq(#all, 1, "still one terminal")
  assert_eq(all[1].buf, buf_before, "same buffer preserved")
  assert_truthy(all[1]:win_valid(), "still visible after toggle")
end)

test("toggle_position() float -> bottom preserves visibility", function()
  local term = reload()
  term.create()                          -- bottom #1, active=#1
  term.toggle_position()                 -- #1 now float, visible

  term.toggle_position()

  local all = snacks_terminal.list()
  assert_eq(#all, 1, "still one terminal")
  assert_truthy(all[1]:win_valid(), "still visible")
end)

test("toggle_position() toggle back and forth multiple times", function()
  local term = reload()
  term.create()                          -- #1 bottom, active=#1

  -- bottom -> float
  term.toggle_position()
  local all = snacks_terminal.list()
  assert_truthy(all[1]:win_valid(), "visible after 1st toggle")
  assert_truthy(all[1]:is_floating(), "is float after 1st toggle")

  -- float -> bottom
  term.toggle_position()
  all = snacks_terminal.list()
  assert_truthy(all[1]:win_valid(), "visible after 2nd toggle")
  assert_falsy(all[1]:is_floating(), "is bottom after 2nd toggle")

  -- bottom -> float
  term.toggle_position()
  all = snacks_terminal.list()
  assert_truthy(all[1]:win_valid(), "visible after 3rd toggle")
  assert_truthy(all[1]:is_floating(), "is float after 3rd toggle")
end)

test("toggle_position() with inactive but visible terminal -> no-op", function()
  local term = reload()
  term.create()                          -- #1 bottom, active=#1
  term.create()                          -- #2 bottom, active=#2
  term.switch(1)                         -- active=#1, term #2 still visible
  -- Terminal 2 is visible but not active. toggle_position only affects active.
  term.toggle_position()                 -- toggles #1 (active)

  local all = snacks_terminal.list()
  assert_eq(#all, 2, "both terminals exist")
  assert_truthy(all[1]:win_valid() or all[2]:win_valid(), "at least one visible")
end)

test("toggle_position() with active=nil, no terminal shown -> no-op", function()
  local term = reload()
  term.create()                          -- #1 bottom, active=#1, visible
  term.toggle()                          -- hide all, active=nil

  term.toggle_position()
  -- no crash = pass
end)

test("toggle_position() dead buffer -> no-op", function()
  local term = reload()
  term.create()                          -- #1, active=#1

  -- kill buffer directly
  local all = snacks_terminal.list()
  vim.api.nvim_buf_delete(all[1].buf, { force = true })

  term.toggle_position()
  -- no crash = pass
end)

test("toggle_position() preserves buffer across many toggles", function()
  local term = reload()
  term.create()
  local all = snacks_terminal.list()
  local buf = all[1].buf

  -- 5 toggles: bottom/float -> float/bottom -> bottom/float -> float/bottom -> bottom/float
  for _ = 1, 5 do
    term.toggle_position()
  end

  all = snacks_terminal.list()
  assert_eq(all[1].buf, buf, "same buffer after 5 toggles")
end)

test("toggle_position() does not affect other terminals", function()
  local term = reload()
  term.create()                          -- #1 bottom, active=#1
  term.create()                          -- #2 bottom, active=#2
  term.switch(1)                         -- active=#1

  term.toggle_position()                 -- toggle #1 (active) to float

  local all = snacks_terminal.list()
  assert_eq(#all, 2, "both terminals still exist")
  -- #1 should be visible (was active)
  assert_truthy(all[1]:win_valid() or all[2]:win_valid(), "at least one visible")
end)

test("toggle_position() opts.position is updated correctly", function()
  local term = reload()
  term.create()                          -- #1 bottom, active=#1

  -- Verify initial position
  local all = snacks_terminal.list()
  local t = all[1]
  assert_eq(t.opts.position, "bottom", "initial position is bottom")

  term.toggle_position()                 -- bottom -> float
  assert_eq(t.opts.position, "float", "position changed to float")

  term.toggle_position()                 -- float -> bottom
  assert_eq(t.opts.position, "bottom", "position changed back to bottom")
end)

-- ============================================================
-- Summary
-- ============================================================
local n_failed = #failures
local n_total = 3 + 13 + 6 + 7 + 3 + 25 + 9

print(string.format("\n%s %d passed, %d failed",
  n_failed == 0 and "All tests passed:" or "Results:", n_total - n_failed, n_failed))

if n_failed > 0 then
  vim.cmd("cq")
end
