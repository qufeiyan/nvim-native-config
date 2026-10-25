---@class utils.treesitter_container
local M = {}

-- Node types that represent structural containers
local containers = {
	class_declaration = true,
	class_definition = true,
	type_declaration = true, -- Go struct/interface
	struct_item = true, -- Rust
	enum_item = true, -- Rust
	trait_item = true, -- Rust
	impl_item = true, -- Rust
	struct_expression = true, -- Rust struct literal: `Foo { x, y }`
}

-- Keywords / type names to skip when guessing a container name from its first named child
local SKIP_WORDS = {
	pub = true, fn = true, struct = true, enum = true, impl = true, class = true,
	def = true, ["local"] = true, int = true, void = true, char = true, float = true,
	double = true, long = true, short = true, unsigned = true, const = true,
	static = true, extern = true, typedef = true,
}

---@param node_type string
local function is_container(node_type)
	if containers[node_type] then
		return true
	end
	if
		node_type:find("_function_", 1)
		or node_type:find("^function_", 1)
		or node_type:find("^method_", 1)
		or node_type:find("_item$", 1)
		or node_type:find("_specifier$", 1) -- C struct/enum/union
	then
		return true
	end
	return false
end

-- Icons: snacks-compatible Nerd Font codepoints (from snacks.picker icons.kinds)
local ICON_FUNCTION  = "󰊕 " -- Function/Method
local ICON_CLASS     = " " -- Class
local ICON_STRUCT    = "󰆼 " -- Struct/Union
local ICON_ENUM      = " " -- Enum
local ICON_INTERFACE = " " -- Interface/Trait
local ICON_MODULE    = "󰦮 " -- Module/Impl/Namespace
local ICON_FALLBACK  = "󰦮 " -- default

local icon_map = {
	function_declaration        = ICON_FUNCTION,
	function_definition         = ICON_FUNCTION,
	local_function_declaration  = ICON_FUNCTION,
	method_declaration          = ICON_FUNCTION,
	method_definition           = ICON_FUNCTION,
	class_declaration           = ICON_CLASS,
	class_definition            = ICON_CLASS,
	struct_item                 = ICON_STRUCT,
	enum_item                   = ICON_ENUM,
	trait_item                  = ICON_INTERFACE,
	impl_item                   = ICON_MODULE,
	type_declaration            = ICON_STRUCT,
	struct_expression           = ICON_STRUCT,
	struct_specifier            = ICON_STRUCT,
	union_specifier             = ICON_STRUCT,
	enum_specifier              = ICON_ENUM,
}

---@param node_type string
---@return string icon
local function get_icon(node_type)
	if icon_map[node_type] then
		return icon_map[node_type]
	end
	if node_type:find("function") then return ICON_FUNCTION end
	if node_type:find("method")   then return ICON_FUNCTION end
	if node_type:find("class")    then return ICON_CLASS end
	if node_type:find("struct")   then return ICON_STRUCT end
	if node_type:find("enum")     then return ICON_ENUM end
	if node_type:find("trait") or node_type:find("interface") then return ICON_INTERFACE end
	if node_type:find("impl")     then return ICON_MODULE end
	if node_type:find("union")    then return ICON_STRUCT end
	return ICON_FALLBACK
end

---Extract the name identifier from a container node
---@param node TSNode
---@param buf integer
---@return string|nil
local function get_name(node, buf)
	-- Pass 1: direct identifier children (Lua, Rust, Python, Go)
	for child in node:iter_children() do
		if child:named() then
			local t = child:type()
			if
				t == "identifier"
				or t == "name"
				or t == "property_identifier"
				or t:find("_identifier$") -- type_identifier, field_identifier etc.
			then
				return vim.treesitter.get_node_text(child, buf)
			end
		end
	end
	-- Pass 2: look inside declarator-like children (C, C++ function names)
	for child in node:iter_children() do
		if child:named() and child:type():find("declarator") then
			for gchild in child:iter_children() do
				if gchild:named() and (gchild:type() == "identifier" or gchild:type():find("_identifier$")) then
					return vim.treesitter.get_node_text(gchild, buf)
				end
			end
		end
	end
	-- Fallback: first named child, skipping keywords and C type names
	for child in node:iter_children() do
		if child:named() then
			local text = vim.treesitter.get_node_text(child, buf)
			if #text < 60 and not SKIP_WORDS[text] then
				return text
			end
		end
	end
	return nil
end

---Find the enclosing container at a buffer position
---@param buf integer
---@param lnum integer 1-based line number
---@return {name:string, icon:string}|nil
function M.get_container(buf, lnum)
	if not buf or buf == 0 then
		return nil
	end

	if not vim.api.nvim_buf_is_loaded(buf) then
		local ok = pcall(vim.fn.bufload, buf)
		if not ok then
			return nil
		end
	end

	local ok, parser = pcall(vim.treesitter.get_parser, buf)
	if not ok or not parser then
		return nil
	end

	local tree = parser:parse()[1]
	if not tree then
		return nil
	end

	local row = lnum - 1
	local node = tree:root():descendant_for_range(row, 0, row, 0)
	if not node then
		return nil
	end

	local current = node
	while current do
		local t = current:type()
		if is_container(t) then
			local name = get_name(current, buf)
			if name then
				return { name = name, icon = get_icon(t) }
			end
		end
		current = current:parent()
	end

	return nil
end

return M
