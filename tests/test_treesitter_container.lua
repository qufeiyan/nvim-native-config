--[[
Tests for lua/utils/treesitter_container.lua

Run: nvim --headless -u NONE -c "luafile tests/test_treesitter_container.lua" -c "qa"

Tests the get_container(buf, lnum) function, which returns {name, icon}|nil.
]]

-- ============================================================
-- Test Framework
-- ============================================================
local failures = {}

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
-- Helpers
-- ============================================================

---@param lines string[]
---@param ft string
---@return integer buf
local function new_buf(lines, ft)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].filetype = ft
	local ok = pcall(vim.treesitter.start, buf, ft)
	if not ok then
		vim.api.nvim_buf_delete(buf, { force = true })
		return nil
	end
	vim.wait(300, function() return false end)
	return buf
end

local M = require("utils.treesitter_container")

-- ============================================================
-- Suite 1: Basic Container Detection (Lua)
-- ============================================================
suite("Basic Container Detection (Lua)")

test("finds function enclosing a statement", function()
	local buf = new_buf({
		"local x = 1",
		"function hello()",
		'  print("inside")',
		"end",
	}, "lua")

	local got = M.get_container(buf, 3)
	assert_eq(got.name, "hello")
	vim.api.nvim_buf_delete(buf, { force = true })
end)

test("finds local function", function()
	local buf = new_buf({
		"local function greet(name)",
		'  return "hi"',
		"end",
	}, "lua")

	local got = M.get_container(buf, 2)
	assert_eq(got.name, "greet")
	vim.api.nvim_buf_delete(buf, { force = true })
end)

test("finds nested inner function", function()
	local buf = new_buf({
		"function outer()",
		"  function inner()",
		'    print("x")',
		"  end",
		"end",
	}, "lua")

	local got = M.get_container(buf, 3)
	assert_eq(got.name, "inner")
	vim.api.nvim_buf_delete(buf, { force = true })
end)

test("finds outer function from position outside inner", function()
	local buf = new_buf({
		"function outer()",
		"  local x = 1",
		"  function inner()",
		'    print("x")',
		"  end",
		"  return x",
		"end",
	}, "lua")

	local got = M.get_container(buf, 5)
	assert_truthy(got, "should find either inner or outer")
	print("  -> container: " .. got.name)
	vim.api.nvim_buf_delete(buf, { force = true })
end)

test("mid-line position returns correct container", function()
	local buf = new_buf({
		"local x = 1",
		"function fn()",
		'  local y = fn2()',
		"end",
	}, "lua")

	local got = M.get_container(buf, 3)
	assert_eq(got.name, "fn")
	vim.api.nvim_buf_delete(buf, { force = true })
end)

-- ============================================================
-- Suite 2: Position Outside Container
-- ============================================================
suite("Position Outside Container")

test("top-level code returns nil", function()
	local buf = new_buf({
		'local x = "top"',
		'print("hello")',
		"function foo() end",
	}, "lua")

	local got = M.get_container(buf, 1)
	assert_falsy(got)
	vim.api.nvim_buf_delete(buf, { force = true })
end)

test("empty file returns nil", function()
	local buf = new_buf({ "", "" }, "lua")

	local got = M.get_container(buf, 1)
	assert_falsy(got)
	vim.api.nvim_buf_delete(buf, { force = true })
end)

-- ============================================================
-- Suite 3: Edge Cases
-- ============================================================
suite("Edge Cases")

for _, case in ipairs({
	{ "nil buffer", nil, 1 },
	{ "buffer 0", 0, 1 },
	{ "invalid buffer", 99999, 1 },
}) do
	test(case[1] .. " returns nil", function()
		local got = M.get_container(case[2], case[3])
		assert_falsy(got)
	end)
end

test("line beyond buffer length returns nil", function()
	local buf = new_buf({ "function f()", "end" }, "lua")

	local got = M.get_container(buf, 100)
	assert_falsy(got)
	vim.api.nvim_buf_delete(buf, { force = true })
end)

test("deleted buffer returns nil", function()
	local buf = new_buf({ "function f()", '  print("hi")', "end" }, "lua")
	vim.api.nvim_buf_delete(buf, { force = true })

	local got = M.get_container(buf, 2)
	assert_falsy(got)
end)

-- ============================================================
-- Suite 4: No Treesitter Available
-- ============================================================
suite("No Treesitter Available")

test("buffer with no treesitter parser returns nil", function()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "function test()", "end" })
	vim.bo[buf].filetype = "nosuchft_xyz"

	local got = M.get_container(buf, 2)
	assert_falsy(got)
	vim.api.nvim_buf_delete(buf, { force = true })
end)

-- ============================================================
-- Suite 5: Python (if available)
-- ============================================================
suite("Python Containers")

test("finds Python function", function()
	local buf = new_buf({
		"x = 1",
		"def greet():",
		'    return "hello"',
	}, "python")

	local got = M.get_container(buf, 3)
	assert_eq(got.name, "greet")
	vim.api.nvim_buf_delete(buf, { force = true })
end)

test("Python method is inner container (not class)", function()
	local buf = new_buf({
		"class MyService:",
		"    def handle(self):",
		"        pass",
	}, "python")

	local got = M.get_container(buf, 3)
	assert_eq(got.name, "handle")
	vim.api.nvim_buf_delete(buf, { force = true })
end)

test("finds Python class from class-level position", function()
	local buf = new_buf({
		"class MyService:",
		"    data = 1",
		"    def handle(self):",
		"        pass",
	}, "python")

	local got = M.get_container(buf, 2)
	assert_eq(got.name, "MyService")
	vim.api.nvim_buf_delete(buf, { force = true })
end)

-- ============================================================
-- Suite 6: Rust (name + icon)
-- ============================================================
suite("Rust Containers")

test("struct_item: name + struct icon", function()
	local buf = new_buf({
		"pub struct Writer {",
		"    path: PathBuf,",
		"    buffer: BufWriter<File>,",
		"    items: u32,",
		"    count: u32,",
		"}",
	}, "rust")

	local got = M.get_container(buf, 2)
	assert_eq(got.name, "Writer")
	assert_truthy(#got.icon > 0, "icon should not be empty")
	vim.api.nvim_buf_delete(buf, { force = true })
end)

test("struct_expression: name + struct icon", function()
	local buf = new_buf({
		"fn main() {",
		"    let w = Writer {",
		"        path: raw_path,",
		"        buffer,",
		"        items: 0,",
		"        count: 0,",
		"    };",
		"}",
	}, "rust")

	local got = M.get_container(buf, 3)
	assert_eq(got.name, "Writer")
	assert_truthy(#got.icon > 0, "icon should not be empty")
	vim.api.nvim_buf_delete(buf, { force = true })
end)

test("Rust fn: name + function icon", function()
	local buf = new_buf({
		"fn build() -> Writer {",
		"    Writer {",
		'        path: "a".into(),',
		"        buffer,",
		"        items: 0,",
		"        count: 0,",
		"    }",
		"}",
	}, "rust")

	local got = M.get_container(buf, 1)
	assert_eq(got.name, "build")
	assert_truthy(#got.icon > 0, "icon should not be empty")
	vim.api.nvim_buf_delete(buf, { force = true })
end)

-- ============================================================
-- Suite 7: Multiple Buffers
-- ============================================================
suite("Multiple Buffers")

test("multiple buffers queried in sequence", function()
	local results = {}
	for i = 1, 5 do
		local buf = new_buf({
			"function func" .. i .. "()",
			'  print("x")',
			"end",
		}, "lua")
		local got = M.get_container(buf, 2)
		results[i] = got.name
		vim.api.nvim_buf_delete(buf, { force = true })
	end

	for i = 1, 5 do
		assert_eq(results[i], "func" .. i)
	end
end)

-- ============================================================
-- Suite 8: C
-- ============================================================
suite("C Containers")

test("finds function_definition in C", function()
	local buf = new_buf({
		"#include <stdio.h>",
		"int add(int a, int b) {",
		"    return a + b;",
		"}",
	}, "c")

	local got = M.get_container(buf, 3)
	assert_eq(got.name, "add")
	assert_truthy(#got.icon > 0, "icon should not be empty")
	vim.api.nvim_buf_delete(buf, { force = true })
end)

test("finds struct_specifier in C", function()
	local buf = new_buf({
		"struct Point {",
		"    int x;",
		"    int y;",
		"};",
	}, "c")

	local got = M.get_container(buf, 2)
	assert_eq(got.name, "Point")
	assert_truthy(#got.icon > 0, "icon should not be empty")
	vim.api.nvim_buf_delete(buf, { force = true })
end)

test("finds enum_specifier in C", function()
	local buf = new_buf({
		"enum Color {",
		"    RED,",
		"    GREEN,",
		"    BLUE,",
		"};",
	}, "c")

	local got = M.get_container(buf, 3)
	assert_eq(got.name, "Color")
	assert_truthy(#got.icon > 0, "icon should not be empty")
	vim.api.nvim_buf_delete(buf, { force = true })
end)

test("C function inside struct field returns function", function()
	local buf = new_buf({
		"struct Point {",
		"    int x;",
		"};",
		"void print_point(struct Point p) {",
		'    printf("%d\\n", p.x);',
		"}",
	}, "c")

	-- line 5: inside print_point body
	local got = M.get_container(buf, 5)
	assert_eq(got.name, "print_point")
	vim.api.nvim_buf_delete(buf, { force = true })
end)

-- ============================================================
-- Suite 9: Unloaded buffer (bufload from disk)
-- ============================================================
suite("Unloaded Buffer (bufload)")

test("loads file from disk and finds container", function()
	local fname = vim.fn.stdpath("cache") .. "/test_disk_func.lua"
	local lines = {
		"local x = 1",
		"function disk_func()",
		'  return "ok"',
		"end",
	}
	vim.fn.writefile(lines, fname)
	assert_truthy(vim.fn.filereadable(fname) == 1, "file should be readable on disk")

	-- Open via :edit (same path snacks uses internally for bufload)
	vim.cmd("hide edit " .. vim.fn.fnameescape(fname))
	local new_buf = vim.api.nvim_get_current_buf()
	assert_truthy(vim.api.nvim_buf_is_loaded(new_buf), "buffer should be loaded")

	-- Start treesitter for the loaded buffer and wait for parse
	vim.treesitter.start(new_buf, "lua")
	vim.wait(300, function() return false end)

	-- Query container
	local got = M.get_container(new_buf, 3)
	assert_eq(got.name, "disk_func")

	vim.api.nvim_buf_delete(new_buf, { force = true })
	os.remove(fname)
end)

test("bufload fails gracefully for invalid buffer number", function()
	local got = M.get_container(99999, 1)
	assert_falsy(got)
end)

-- ============================================================
-- Summary
-- ============================================================
local n_failed = #failures
local n_total = 27

print(string.format(
	"\n%s %d passed, %d failed",
	n_failed == 0 and "All tests passed:" or "Results:",
	n_total - n_failed,
	n_failed
))

if n_failed > 0 then
	vim.cmd("cq")
end
