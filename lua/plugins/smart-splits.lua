-- smart-splits.nvim: seamless Neovim ↔ Zellij pane navigation
-- See: https://github.com/mrjones2014/smart-splits.nvim

vim.pack.add({
    { src = "https://github.com/mrjones2014/smart-splits.nvim" },
})

require("smart-splits").setup({
    at_edge = "stop",
    default_amount = 3,
    move_cursor_same_row = false,
    cursor_follows_swapped_bufs = false,
    multiplexer_integration = nil, -- auto-detect
    disable_multiplexer_nav_when_zoomed = true,
    log_level = "info",
})

-- recommended mappings from README
-- resizing splits (accepts a range, e.g. 10<A-h>)
vim.keymap.set("n", "<A-h>", require("smart-splits").resize_left)
vim.keymap.set("n", "<A-j>", require("smart-splits").resize_down)
vim.keymap.set("n", "<A-k>", require("smart-splits").resize_up)
vim.keymap.set("n", "<A-l>", require("smart-splits").resize_right)
-- moving between splits
vim.keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left)
vim.keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down)
vim.keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up)
vim.keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right)
vim.keymap.set("n", "<C-\\>", require("smart-splits").move_cursor_previous)
-- swapping buffers between windows
vim.keymap.set("n", "<leader>wh", require("smart-splits").swap_buf_left)
vim.keymap.set("n", "<leader>wj", require("smart-splits").swap_buf_down)
vim.keymap.set("n", "<leader>wk", require("smart-splits").swap_buf_up)
vim.keymap.set("n", "<leader>wl", require("smart-splits").swap_buf_right)
