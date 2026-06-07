-- Python LSP using Neovim's native vim.lsp (works on 0.10.x; no nvim-lspconfig).
-- Servers are installed globally with: uv tool install basedpyright ruff

-- Make sure uv's tool binaries are discoverable even when nvim is not launched
-- from an interactive shell.
local local_bin = vim.fn.expand("~/.local/bin")
if not string.find(vim.env.PATH or "", local_bin, 1, true) then
    vim.env.PATH = local_bin .. ":" .. (vim.env.PATH or "")
end

vim.diagnostic.config({
    severity_sort = true,
    virtual_text = true,
    float = { border = "rounded", source = true },
})

-- Resolve the interpreter for the active venv ($VIRTUAL_ENV) or a project-local
-- .venv/venv, falling back to whatever `python3` is on PATH (the uv default).
local function python_path(root)
    local venv = vim.env.VIRTUAL_ENV
    if venv and venv ~= "" then
        return venv .. "/bin/python"
    end
    for _, name in ipairs({ ".venv", "venv" }) do
        local cand = root .. "/" .. name .. "/bin/python"
        if vim.uv.fs_stat(cand) then
            return cand
        end
    end
    return vim.fn.exepath("python3")
end

local function on_attach(_, bufnr)
    local map = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = "LSP: " .. desc })
    end
    map("gd", vim.lsp.buf.definition, "definition")
    map("gr", vim.lsp.buf.references, "references")
    map("gi", vim.lsp.buf.implementation, "implementation")
    map("K", vim.lsp.buf.hover, "hover")
    map("<leader>rn", vim.lsp.buf.rename, "rename")
    map("<leader>ca", vim.lsp.buf.code_action, "code action")
    map("[d", vim.diagnostic.goto_prev, "prev diagnostic")
    map("]d", vim.diagnostic.goto_next, "next diagnostic")
end

local function capabilities()
    local ok, blink = pcall(require, "blink.cmp")
    if ok then
        return blink.get_lsp_capabilities()
    end
    return vim.lsp.protocol.make_client_capabilities()
end

local function start(bufnr)
    local root = vim.fs.root(bufnr, {
        "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git",
    }) or vim.fn.getcwd()
    local caps = capabilities()

    -- basedpyright: types, completion, navigation
    if vim.fn.executable("basedpyright-langserver") == 1 then
        vim.lsp.start({
            name = "basedpyright",
            cmd = { "basedpyright-langserver", "--stdio" },
            root_dir = root,
            capabilities = caps,
            on_attach = on_attach,
            settings = {
                basedpyright = {
                    analysis = {
                        typeCheckingMode = "standard",
                        diagnosticMode = "openFilesOnly",
                        autoImportCompletions = true,
                    },
                },
                python = { pythonPath = python_path(root) },
            },
        }, { bufnr = bufnr })
    end

    -- ruff: linting + code actions (formatting is handled by conform.nvim)
    if vim.fn.executable("ruff") == 1 then
        vim.lsp.start({
            name = "ruff",
            cmd = { "ruff", "server" },
            root_dir = root,
            capabilities = caps,
            on_attach = on_attach,
        }, { bufnr = bufnr })
    end
end

local group = vim.api.nvim_create_augroup("UserPythonLsp", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "python",
    callback = function(args)
        start(args.buf)
    end,
})
