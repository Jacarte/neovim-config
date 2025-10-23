-- LSP helper function

local cmd = vim.cmd

local M = {}

cmd([[autocmd ColorScheme * highlight NormalFloat guibg=#1f2335]])
cmd([[autocmd ColorScheme * highlight FloatBorder guifg=white guibg=#1f2335]])

-- This function defines the on_attach function for several languages which share the same key-bidings
function M.common_on_attach(client, bufnr)
  vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
  local ft = vim.bo[bufnr].filetype

  -- Helper function
  local opts = {noremap = true, silent = true}
  local function bufnnoremap(lhs, rhs)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', lhs, rhs, opts)
  end

  -- Keymaps: we need to define keymaps for each of the LSP functionalities manually
  -- Go to definition and declaration (use leader to presever standard use of 'gd')
  bufnnoremap("<leader>gd", "<Cmd>lua vim.lsp.buf.definition()<CR>")
  bufnnoremap("<leader>gD", "<Cmd>lua vim.lsp.buf.declaration()<CR>")

  -- Go to implementation
  bufnnoremap("<leader>gi", "<Cmd>lua vim.lsp.buf.implementation()<CR>")

  -- List symbol uses
  -- bufnnoremap("<leader>gr", "<cmd>lua vim.lsp.buf.references()<CR>")  -- Uses quickfix
  bufnnoremap("<leader>gr", "<cmd>Telescope lsp_references<CR>")  -- Uses Telescope

  -- Inspect function
  bufnnoremap("K", "<Cmd>lua vim.lsp.buf.hover()<CR>")

  -- Signature help
  bufnnoremap("<A-k>", "<Cmd>lua vim.lsp.buf.signature_help()<CR>")

  -- Rename all references of symbol
  bufnnoremap("<leader>R", "<Cmd>lua vim.lsp.buf.rename()<CR>")

  -- Navigate diagnostics
  bufnnoremap("<C-n>", "<Cmd>lua vim.diagnostic.goto_next()<CR>")
  bufnnoremap("<C-p>", "<Cmd>lua vim.diagnostic.goto_prev()<CR>")
  bufnnoremap("<leader>ga", "<Cmd>lua vim.lsp.buf.code_action()<CR>")


  -- Show documentation
  bufnnoremap("<leader>h",  "<Cmd>lua vim.lsp.buf.hover()<CR>")

  -- Tests

  bufnnoremap('<Leader>tt', ':lua require("neotest").run.run()<CR>', { desc = 'Run test' })
  -- Markdown preview TODO: make this conditional, but I also don't use it all that much
  -- bufnnnoremap("<leader>P", "<Cmd>Glow<CR>")

  if ft == "go" then
    M.setup_reference_count_display(bufnr)
  end
end

function M.setup_reference_count_display(bufnr)
  local namespace = vim.api.nvim_create_namespace('reference_count')

  local function update_reference_counts()
    vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

    local params = {
      textDocument = vim.lsp.util.make_text_document_params(bufnr)
    }

    vim.lsp.buf_request(bufnr, 'textDocument/documentSymbol', params, function(err, result, ctx, config)
      if err or not result then return end

      local function process_symbols(symbols)
        for _, symbol in ipairs(symbols) do
          if symbol.kind == 8 or symbol.kind == 6 or symbol.kind == 12 then
            local range = symbol.range or symbol.location.range
            local line = range.start.line

            local ref_params = {
              textDocument = vim.lsp.util.make_text_document_params(bufnr),
              position = range.start,
              context = { includeDeclaration = false }
            }

            vim.lsp.buf_request(bufnr, 'textDocument/references', ref_params, function(ref_err, references, ref_ctx, ref_config)
              if ref_err then return end

              local count = references and #references or 0
              local hl_group = count == 0 and 'WarningMsg' or 'Comment'

              vim.api.nvim_buf_set_extmark(bufnr, namespace, line, 0, {
                virt_text = {{string.format(' [%d refs]', count), hl_group}},
                virt_text_pos = 'eol',
              })
            end)
          end

          if symbol.children then
            process_symbols(symbol.children)
          end
        end
      end

      process_symbols(result)
    end)
  end

  vim.api.nvim_create_autocmd({'BufEnter', 'BufWritePost', 'TextChanged', 'InsertLeave'}, {
    buffer = bufnr,
    callback = update_reference_counts,
  })

  update_reference_counts()
end

return M
