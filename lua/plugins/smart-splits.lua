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
vim.keymap.set("n", "<A-h>", require("smart-splits").resize_left, { desc = "Resize split left" })
vim.keymap.set("n", "<A-j>", require("smart-splits").resize_down, { desc = "Resize split down" })
vim.keymap.set("n", "<A-k>", require("smart-splits").resize_up, { desc = "Resize split up" })
vim.keymap.set("n", "<A-l>", require("smart-splits").resize_right, { desc = "Resize split right" })
-- moving between splits
vim.keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left, { desc = "Move to left split" })
vim.keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down, { desc = "Move to split below" })
vim.keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up, { desc = "Move to split above" })
vim.keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right, { desc = "Move to right split" })
vim.keymap.set("n", "<C-\\>", require("smart-splits").move_cursor_previous, { desc = "Move to previous split" })
-- swapping buffers between windows
vim.keymap.set("n", "<leader>wh", require("smart-splits").swap_buf_left, { desc = "Swap buffer left" })
vim.keymap.set("n", "<leader>wj", require("smart-splits").swap_buf_down, { desc = "Swap buffer down" })
vim.keymap.set("n", "<leader>wk", require("smart-splits").swap_buf_up, { desc = "Swap buffer up" })
vim.keymap.set("n", "<leader>wl", require("smart-splits").swap_buf_right, { desc = "Swap buffer right" })
