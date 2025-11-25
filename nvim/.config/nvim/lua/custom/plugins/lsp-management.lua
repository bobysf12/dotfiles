return {
    "neovim/nvim-lspconfig",
    lazy = true,
    config = function()
        -- Helper function to auto-start LSP if needed
        local function ensure_lsp_started()
            local clients = vim.lsp.get_active_clients()
            if #clients == 0 then
                vim.cmd("LspStart")
                -- Give LSP a moment to start
                vim.defer_fn(function()
                    vim.notify("LSP started automatically", vim.log.levels.INFO)
                end, 100)
            end
        end

        -- Set up global LSP keymaps that auto-start LSP on first use
        local lsp_keymaps = {
            {
                "gd",
                function()
                    ensure_lsp_started()
                    require("telescope.builtin").lsp_definitions()
                end,
                desc = "[G]oto [D]efinition",
            },
            {
                "gr",
                function()
                    ensure_lsp_started()
                    require("telescope.builtin").lsp_references()
                end,
                desc = "[G]oto [R]eferences",
            },
            {
                "gI",
                function()
                    ensure_lsp_started()
                    require("telescope.builtin").lsp_implementations()
                end,
                desc = "[G]oto [I]mplementation",
            },
            {
                "<leader>D",
                function()
                    ensure_lsp_started()
                    require("telescope.builtin").lsp_type_definitions()
                end,
                desc = "Type [D]efinition",
            },
            {
                "<leader>ds",
                function()
                    ensure_lsp_started()
                    require("telescope.builtin").lsp_document_symbols()
                end,
                desc = "[D]ocument [S]ymbols",
            },
            {
                "<leader>ws",
                function()
                    ensure_lsp_started()
                    require("telescope.builtin").lsp_dynamic_workspace_symbols()
                end,
                desc = "[W]orkspace [S]ymbols",
            },
            {
                "<leader>cr",
                function()
                    ensure_lsp_started()
                    vim.lsp.buf.rename()
                end,
                desc = "Rename Variable",
            },
            {
                "<leader>ca",
                function()
                    ensure_lsp_started()
                    vim.lsp.buf.code_action()
                end,
                desc = "Code Action",
            },
            {
                "gD",
                function()
                    ensure_lsp_started()
                    vim.lsp.buf.declaration()
                end,
                desc = "[G]oto [D]eclaration",
            },
        }

        -- Register all LSP keymaps
        for _, keymap in ipairs(lsp_keymaps) do
            vim.keymap.set("n", keymap[1], keymap[2], { desc = "LSP: " .. keymap.desc, noremap = true })
        end

        -- Code action can also work in visual mode
        vim.keymap.set("x", "<leader>ca", function()
            ensure_lsp_started()
            vim.lsp.buf.code_action()
        end, { desc = "LSP: Code Action", noremap = true })

        -- Management keymaps (with leader)
        vim.keymap.set("n", "<leader>ld", function()
            vim.cmd("LspInfo")
        end, { desc = "[L]SP [D]iagnostics/Info" })

        vim.keymap.set("n", "<leader>ls", function()
            vim.cmd("LspStart")
            vim.notify("LSP started", vim.log.levels.INFO)
        end, { desc = "[L]SP [S]tart" })

        vim.keymap.set("n", "<leader>lk", function()
            vim.cmd("LspStop")
            vim.notify("LSP stopped", vim.log.levels.INFO)
        end, { desc = "[L]SP Sto[p]" })

        vim.keymap.set("n", "<leader>lr", function()
            vim.cmd("LspRestart")
            vim.notify("LSP restarted", vim.log.levels.INFO)
        end, { desc = "[L]SP [R]estart" })

        vim.keymap.set("n", "<leader>ll", function()
            local clients = vim.lsp.get_active_clients()
            if #clients == 0 then
                vim.notify("No active LSP clients", vim.log.levels.INFO)
            else
                local client_names = {}
                for _, client in ipairs(clients) do
                    table.insert(client_names, client.name)
                end
                vim.notify("Active LSP: " .. table.concat(client_names, ", "), vim.log.levels.INFO)
            end
        end, { desc = "[L]SP [L]ist active" })

        -- Toggle diagnostics
        vim.keymap.set("n", "<leader>td", function()
            local is_enabled = #vim.diagnostic.get(0) > 0
            if is_enabled then
                vim.diagnostic.disable()
                vim.notify("Diagnostics disabled", vim.log.levels.INFO)
            else
                vim.diagnostic.enable()
                vim.notify("Diagnostics enabled", vim.log.levels.INFO)
            end
        end, { desc = "[T]oggle [D]iagnostics" })

        -- Create user commands for LSP management
        vim.api.nvim_create_user_command("LspToggle", function()
            local clients = vim.lsp.get_active_clients()
            if #clients > 0 then
                vim.cmd("LspStop")
                vim.notify("LSP stopped", vim.log.levels.INFO)
            else
                vim.cmd("LspStart")
                vim.notify("LSP started", vim.log.levels.INFO)
            end
        end, {})

        vim.api.nvim_create_user_command("LspStatus", function()
            local clients = vim.lsp.get_active_clients()
            if #clients == 0 then
                vim.notify("No active LSP clients", vim.log.levels.INFO)
            else
                local client_names = {}
                for _, client in ipairs(clients) do
                    table.insert(client_names, client.name)
                end
                vim.notify("Active LSP: " .. table.concat(client_names, ", "), vim.log.levels.INFO)
            end
        end, {})

        vim.api.nvim_create_user_command("DiagnosticsEnable", function()
            vim.diagnostic.enable()
            vim.notify("Diagnostics enabled", vim.log.levels.INFO)
        end, {})

        vim.api.nvim_create_user_command("DiagnosticsDisable", function()
            vim.diagnostic.disable()
            vim.notify("Diagnostics disabled", vim.log.levels.INFO)
        end, {})

        vim.api.nvim_create_user_command("DiagnosticsToggle", function()
            local is_enabled = #vim.diagnostic.get(0) > 0
            if is_enabled then
                vim.diagnostic.disable()
                vim.notify("Diagnostics disabled", vim.log.levels.INFO)
            else
                vim.diagnostic.enable()
                vim.notify("Diagnostics enabled", vim.log.levels.INFO)
            end
        end, {})
    end,
}
