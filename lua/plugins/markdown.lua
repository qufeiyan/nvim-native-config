vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("SetupRenderMarkdown", { clear = true }),
    pattern = { "markdown", "Avante", "codecompanion" },
    once = true,
    callback = function()
        vim.pack.add({
            { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
        })
        require("render-markdown").setup({
            completions = { lsp = { enabled = true } },
            file_types = { "markdown", "Avante" },
            ft = {
                "markdown",
                -- "Avante",
                "codecompanion"
            },
        })
    end,
})

-- vim.pack.add({
--     { src = "https://github.com/HakonHarnes/img-clip.nvim" },
-- })

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("SetupImgClip", { clear = true }),
    pattern = { "typst", "tex", "markdown" },
    once = true,
    callback = function()
        require("img-clip").setup({
            default = {
                dir_path = "./assets",
                use_absolsnackute_path = false,
                copy_images = true,
                prompt_for_file_name = false,
                file_name = "%y%m%d-%H%M%S",
                extension = "avif",
                process_cmd = "magick convert - -quality 75 avif:-",
                formats = { "jpeg", "jpg", "png" },
            },
            filetypes = {
                markdown = {
                    template = "![image$CURSOR]($FILE_PATH)",
                },
                typst = {
                    dir_path = "./figs",
                    extension = "png",
                    process_cmd = "magick convert - -density 300 png:-",
                    formats = { "jpeg", "jpg", "png", "pdf", "svg" }, ---@type table
                    template = [[
          #align(center)[#image("$FILE_PATH", height: 80%)]
          ]],
                },
            },
        })
        vim.keymap.set("n", "<leader>P", "<cmd>PasteImage<cr>", { desc = "Paste image from system clipboard" })

        vim.keymap.set("n", "<leader>fp", function()
            Snacks.picker.files {
                ft = { "jpg", "jpeg", "png", "webp" },
                confirm = function(self, item, _)
                    self:close()
                    require("img-clip").paste_image({}, "./" .. item.file) -- ./ is necessary for img-clip to recognize it as path
                end,
            }
        end, { desc = "Paste image from system clipboard as markdown" })
    end,
})
