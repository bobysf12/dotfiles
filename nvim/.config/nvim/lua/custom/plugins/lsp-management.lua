return {
    "neovim/nvim-lspconfig",
    -- Don't let lazy.nvim handle loading, we'll manage it manually
    lazy = true,
    keys = {
        {
            "<leader>ld",
            function()
                vim.cmd("LspInfo")
            end,
            desc = "[L]SP [D]iagnostics/Info",
        },
        {
            "<leader>ls",
            function()
                vim.cmd("LspStart")
            end,
            desc = "[L]SP [S]tart",
        },
        {
            "<leader>lk",
            function()
                vim.cmd("LspStop")
            end,
            desc = "[L]SP Sto[p]",
        },
        {
            "<leader>lr",
            function()
                vim.cmd("LspRestart")
            end,
            desc = "[L]SP [R]estart",
        },
        {
            "<leader>ll",
            function()
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
            end,
            desc = "[L]SP [L]ist active",
        },
    },
    config = function()
        -- Create commands for LSP management
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
            local is_enabled = vim.fn.getloclist(0, { winid = 0 }).winid > 0 or
                vim.fn.getqflist({ winid = 0 }).winid > 0
            if is_enabled or next(vim.diagnostic.get(0)) then
                vim.diagnostic.disable()
                vim.notify("Diagnostics disabled", vim.log.levels.INFO)
            else
                vim.diagnostic.enable()
                vim.notify("Diagnostics enabled", vim.log.levels.INFO)
            end
        end, {})

        -- Add keymap for diagnostics
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
    end,
}
