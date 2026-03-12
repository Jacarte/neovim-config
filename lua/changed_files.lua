local M = {}

local state = {
  root = nil,
  files = {},
  index = 0,
}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

local function get_git_root()
  local root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
  if vim.v.shell_error ~= 0 or not root or root == '' then
    return nil
  end
  return root
end

local function list_changed_files(root)
  local cmd = 'git -C ' .. vim.fn.shellescape(root) .. ' diff --name-only'
  local output = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return {}
  end

  local files = {}
  for _, line in ipairs(output) do
    if line and line ~= '' then
      table.insert(files, line)
    end
  end
  return files
end

local function set_state(root, files, index)
  state.root = root
  state.files = files
  state.index = index
end

local function open_at_index(index)
  if not state.root or not state.files or #state.files == 0 then
    notify('No changed files list available. Run :ChangedFiles first.', vim.log.levels.WARN)
    return
  end

  if index < 1 then
    index = #state.files
  elseif index > #state.files then
    index = 1
  end

  state.index = index
  local rel_path = state.files[state.index]
  local abs_path = state.root .. '/' .. rel_path
  vim.cmd('edit ' .. vim.fn.fnameescape(abs_path))
  notify(string.format('[%d/%d] %s', state.index, #state.files, rel_path))
end

local function open_with_quickfix(root, files)
  local qf_items = {}
  for _, rel_path in ipairs(files) do
    table.insert(qf_items, {
      filename = root .. '/' .. rel_path,
      text = rel_path,
    })
  end
  vim.fn.setqflist({}, ' ', {
    title = 'Git Changed Files',
    items = qf_items,
  })
  vim.cmd('copen')
end

local function make_diff_previewer(root)
  local previewers = require('telescope.previewers')

  return previewers.new_buffer_previewer({
    title = 'Git Diff',
    define_preview = function(self, entry)
      vim.bo[self.state.bufnr].modifiable = true

      local rel_path = entry and entry.value or nil
      if not rel_path or rel_path == '' then
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { 'No file selected.' })
        vim.bo[self.state.bufnr].modifiable = false
        return
      end

      local cmd = 'git -C '
        .. vim.fn.shellescape(root)
        .. ' diff -- '
        .. vim.fn.shellescape(rel_path)

      local diff_lines = vim.fn.systemlist(cmd)
      if vim.v.shell_error ~= 0 then
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { 'Failed to render git diff preview.' })
        vim.bo[self.state.bufnr].modifiable = false
        return
      end

      if #diff_lines == 0 then
        diff_lines = { 'No unstaged diff output for this file.' }
      end

      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, diff_lines)
      vim.bo[self.state.bufnr].filetype = 'diff'
      vim.bo[self.state.bufnr].modifiable = false
    end,
  })
end

function M.open_picker()
  local root = get_git_root()
  if not root then
    notify('Not inside a git repository.', vim.log.levels.ERROR)
    return
  end

  local files = list_changed_files(root)
  if #files == 0 then
    notify('No changed files found from `git diff --name-only`.', vim.log.levels.INFO)
    set_state(root, {}, 0)
    return
  end

  local has_telescope = pcall(require, 'telescope')
  if not has_telescope then
    set_state(root, files, 1)
    open_with_quickfix(root, files)
    notify('Telescope not available. Opened changed files in quickfix.', vim.log.levels.WARN)
    return
  end

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  pickers.new({}, {
    prompt_title = 'Git Changed Files',
    cwd = root,
    finder = finders.new_table({
      results = files,
      entry_maker = function(rel_path)
        return {
          value = rel_path,
          display = rel_path,
          ordinal = rel_path,
          filename = root .. '/' .. rel_path,
        }
      end,
    }),
    previewer = make_diff_previewer(root),
    sorter = conf.generic_sorter({}),
    layout_strategy = 'horizontal',
    layout_config = {
      prompt_position = 'top',
      preview_width = 0.55,
    },
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        local selected = entry and entry.value or nil
        if not selected then
          return
        end

        local selected_index = 1
        for idx, rel_path in ipairs(files) do
          if rel_path == selected then
            selected_index = idx
            break
          end
        end

        set_state(root, files, selected_index)
        open_at_index(selected_index)
      end)
      return true
    end,
  }):find()
end

function M.next_file()
  open_at_index(state.index + 1)
end

function M.prev_file()
  open_at_index(state.index - 1)
end

return M
