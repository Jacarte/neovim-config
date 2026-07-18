local treesitter = require('nvim-treesitter')

local requested_parsers = {
  'go',
  'lua',
  'typescript',
  'javascript',
  'json',
  'yaml',
  'html',
  'css',
  'bash',
  'python',
  'markdown',
  'scala',
}

local requested = {}
for _, lang in ipairs(requested_parsers) do
  requested[lang] = true
end

local warned = {}
local function warn_once(key, message)
  if warned[key] then
    return
  end

  warned[key] = true
  vim.schedule(function()
    vim.notify(message, vim.log.levels.WARN)
  end)
end

vim.treesitter.language.register('bash', { 'sh' })

local function activate_buffer(buf, report_missing)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end

  local filetype = vim.bo[buf].filetype
  if filetype == '' then
    return
  end

  local lang = vim.treesitter.language.get_lang(filetype)
  if not lang then
    return
  end

  local added, add_err = vim.treesitter.language.add(lang)
  if not added then
    if report_missing and requested[lang] then
      warn_once(
        'missing:' .. lang,
        ('nvim-treesitter: parser %q is still unavailable; run :checkhealth nvim-treesitter and inspect :TSLog (%s)')
          :format(lang, tostring(add_err))
      )
    end
    return
  end

  local started, start_err = pcall(vim.treesitter.start, buf, lang)
  if not started then
    warn_once(
      'start:' .. lang,
      ('nvim-treesitter: failed to start %q highlighting; inspect :TSLog (%s)')
        :format(lang, tostring(start_err))
    )
  end
end

local group = vim.api.nvim_create_augroup('nvim_treesitter_highlight', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = '*',
  callback = function(args)
    activate_buffer(args.buf, false)
  end,
})

for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  activate_buffer(buf, false)
end

local available = {}
for _, lang in ipairs(treesitter.get_available()) do
  available[lang] = true
end

local installable = {}
for _, lang in ipairs(requested_parsers) do
  if available[lang] then
    table.insert(installable, lang)
  else
    warn_once(
      'unavailable:' .. lang,
      ('nvim-treesitter: requested parser %q is absent from the main manifest; verify the parser name before changing the canonical list')
        :format(lang)
    )
  end
end

if #installable > 0 then
  treesitter.install(installable):await(function(err, installed)
    vim.schedule(function()
      if err then
        warn_once(
          'install:error',
          ('nvim-treesitter: parser installation raised an error; inspect :TSLog and run :checkhealth nvim-treesitter (%s)')
            :format(tostring(err))
        )
      elseif not installed then
        warn_once(
          'install:partial',
          'nvim-treesitter: at least one requested parser failed to install; inspect :TSLog and run :checkhealth nvim-treesitter'
        )
      end

      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        activate_buffer(buf, true)
      end
    end)
  end)
end
