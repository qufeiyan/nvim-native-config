-- sidekick.nvim: AI sidekick for Neovim
--   * NES (Next Edit Suggestions) via the Copilot LSP
--   * Integrated terminal for AI CLIs (claude / opencode / ...)
-- Docs: https://github.com/folke/sidekick.nvim
vim.pack.add({
    { src = "https://github.com/folke/sidekick.nvim" },
})

require("sidekick").setup({
    -- Next Edit Suggestions need the official `copilot-language-server`
    -- (`npm i -g @github/copilot-language-server`) plus `:LspCopilotSignIn`.
    -- Without it this stays inert and the CLI integration still works.
    nes = {
        enabled = true,
        debounce = 300,
        diff = {
            inline = "words",
            show = "always",
        },
    },
    cli = {
        watch = true, -- notify Neovim of file changes done by AI CLI tools
        picker = "snacks", -- we already have snacks.nvim
        win = {
            layout = "right",
            split = { width = 80 },
            keys = {
                -- `q` 只在 normal 模式生效，需先 `<c-q>`(stopinsert) 退出终端模式才能按；
                -- 终端模式下直接关窗口用 `<c-.>`，退回上个窗口用 `<c-z>`。
                hide_n = { "q", "hide", mode = "n", desc = "hide the terminal window" },
            },
        },
        -- Persist CLI sessions so they survive leaving the terminal window.
        -- Both tmux and zellij are installed; default to tmux unless inside zellij.
        mux = {
            backend = vim.env.ZELLIJ and "zellij" or "tmux",
            enabled = true,
            create = "terminal",
        },
        -- Only surface the tools that are actually installed.
        tools = {
            claude = {},
            opencode = {},
        },
    },
    copilot = {
        status = { enabled = true, level = vim.log.levels.WARN },
    },
})

local function cli()
    return require("sidekick.cli")
end
local map = vim.keymap

-- <leader>a is the "AI" group (avante is disabled in init.lua, so it is free)
map.set("n", "<leader>aa", function()
    cli().toggle()
end, { desc = "Sidekick toggle CLI" })
map.set("n", "<leader>as", function()
    cli().select()
end, { desc = "Sidekick select CLI" })
map.set("n", "<leader>ao", function()
    cli().toggle({ name = "opencode", focus = true })
end, { desc = "Sidekick toggle opencode" })
map.set("n", "<leader>ac", function()
    cli().toggle({ name = "claude", focus = true })
end, { desc = "Sidekick toggle claude" })
map.set("n", "<leader>ad", function()
    cli().close()
end, { desc = "Sidekick detach CLI" })
map.set({ "n", "x" }, "<leader>at", function()
    cli().send({ msg = "{this}" })
end, { desc = "Sidekick send this" })
map.set("n", "<leader>af", function()
    cli().send({ msg = "{file}" })
end, { desc = "Sidekick send file" })
map.set("x", "<leader>av", function()
    cli().send({ msg = "{selection}" })
end, { desc = "Sidekick send selection" })
map.set({ "n", "x" }, "<leader>ap", function()
    cli().prompt()
end, { desc = "Sidekick select prompt" })
-- focus / hide the CLI window from anywhere (normal / terminal / insert / visual)
map.set({ "n", "t", "i", "x" }, "<C-.>", function()
    cli().focus()
end, { desc = "Sidekick focus CLI" })
-- NES: jump to / apply the pending next-edit suggestion.
-- <Tab> 也会先尝试它（见 plugins/blink.lua），没建议时再落到 snippet / 补全；
-- 这个 <leader>an 是手动替代入口。
map.set("n", "<leader>an", function()
    require("sidekick").nes_jump_or_apply()
end, { desc = "Sidekick apply next edit" })
