local M = {}

local state = {
  root = nil,
  files = {},
  index = 0,
  diff_ref = nil,
  last_branch = nil,
}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

local function apply_gitsigns_base(diff_ref, global)
  local ok, gitsigns = pcall(require, 'gitsigns')
  if not ok or type(gitsigns.change_base) ~= 'function' then
    return
  end

  local apply_global = global == true

  if diff_ref and diff_ref ~= '' then
    pcall(gitsigns.change_base, diff_ref, apply_global)
  else
    if type(gitsigns.reset_base) == 'function' then
      pcall(gitsigns.reset_base, apply_global)
    else
      pcall(gitsigns.change_base, nil, apply_global)
    end
  end
end

local function get_git_root()
  local root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
  if vim.v.shell_error ~= 0 or not root or root == '' then
    return nil
  end
  return root
end

local function list_changed_files(root, diff_ref)
  local cmd = 'git -C ' .. vim.fn.shellescape(root) .. ' diff --name-only'
  if diff_ref and diff_ref ~= '' then
    cmd = cmd .. ' ' .. vim.fn.shellescape(diff_ref)
  end

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

local function list_branches(root)
  local cmd = 'git -C ' .. vim.fn.shellescape(root) .. " for-each-ref --format='%(refname:short)' refs/heads refs/remotes"
  local output = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return {}
  end

  local seen = {}
  local branches = {}
  for _, line in ipairs(output) do
    if line and line ~= '' and not line:match('^.+/HEAD$') and not seen[line] then
      seen[line] = true
      table.insert(branches, line)
    end
  end
  return branches
end

local function set_state(root, files, index, diff_ref)
  state.root = root
  state.files = files
  state.index = index
  state.diff_ref = diff_ref
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
  vim.defer_fn(function()
    apply_gitsigns_base(state.diff_ref, false)
  end, 50)
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

local function make_diff_previewer(root, diff_ref)
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

      local cmd = 'git -C ' .. vim.fn.shellescape(root) .. ' diff'
      if diff_ref and diff_ref ~= '' then
        cmd = cmd .. ' ' .. vim.fn.shellescape(diff_ref)
      end
      cmd = cmd .. ' -- ' .. vim.fn.shellescape(rel_path)

      local diff_lines = vim.fn.systemlist(cmd)
      if vim.v.shell_error ~= 0 then
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { 'Failed to render git diff preview.' })
        vim.bo[self.state.bufnr].modifiable = false
        return
      end

      if #diff_lines == 0 then
        diff_lines = { 'No diff output for this file with current comparison.' }
      end

      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, diff_lines)
      vim.bo[self.state.bufnr].filetype = 'diff'
      vim.bo[self.state.bufnr].modifiable = false
    end,
  })
end

local function open_changed_files_picker(root, files, diff_ref, title)
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  pickers.new({}, {
    prompt_title = title,
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
    previewer = make_diff_previewer(root, diff_ref),
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

        set_state(root, files, selected_index, diff_ref)
        open_at_index(selected_index)
      end)
      return true
    end,
  }):find()
end

function M.open_picker()
  local root = get_git_root()
  if not root then
    notify('Not inside a git repository.', vim.log.levels.ERROR)
    return
  end

  apply_gitsigns_base(nil, true)

  local files = list_changed_files(root, nil)
  if #files == 0 then
    notify('No changed files found from `git diff --name-only`.', vim.log.levels.INFO)
    set_state(root, {}, 0, nil)
    return
  end

  local has_telescope = pcall(require, 'telescope')
  if not has_telescope then
    set_state(root, files, 1, nil)
    open_with_quickfix(root, files)
    notify('Telescope not available. Opened changed files in quickfix.', vim.log.levels.WARN)
    return
  end

  open_changed_files_picker(root, files, nil, 'Git Changed Files')
end

function M.open_picker_against_branch(force_select)
  local root = get_git_root()
  if not root then
    notify('Not inside a git repository.', vim.log.levels.ERROR)
    return
  end

  if not force_select and state.last_branch and state.last_branch ~= '' then
    local diff_ref = state.last_branch
    local files = list_changed_files(root, diff_ref)
    if #files > 0 then
      apply_gitsigns_base(diff_ref, true)
      open_changed_files_picker(root, files, diff_ref, 'Changed vs ' .. diff_ref)
      return
    end
    notify('No changed files found against remembered branch ' .. diff_ref .. '. Pick another branch.', vim.log.levels.INFO)
  end

  local branches = list_branches(root)
  if #branches == 0 then
    notify('No branches found in this repository.', vim.log.levels.WARN)
    return
  end

  local has_telescope = pcall(require, 'telescope')
  if not has_telescope then
    vim.ui.select(branches, { prompt = 'Select branch to compare:' }, function(branch)
      if not branch or branch == '' then
        return
      end

      local diff_ref = branch
      local files = list_changed_files(root, diff_ref)
      if #files == 0 then
        notify('No changed files found against ' .. diff_ref .. '.', vim.log.levels.INFO)
        set_state(root, {}, 0, diff_ref)
        return
      end

      state.last_branch = branch
      apply_gitsigns_base(diff_ref, true)
      set_state(root, files, 1, diff_ref)
      open_with_quickfix(root, files)
    end)
    return
  end

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  pickers.new({}, {
    prompt_title = 'Compare With Branch (C-r reset)',
    finder = finders.new_table({
      results = branches,
    }),
    sorter = conf.generic_sorter({}),
    layout_strategy = 'horizontal',
    layout_config = {
      prompt_position = 'top',
      preview_width = 0.45,
    },
    attach_mappings = function(prompt_bufnr)
      local function clear_remembered_branch()
        actions.close(prompt_bufnr)
        M.clear_compare_base()
      end

      vim.keymap.set('i', '<C-r>', clear_remembered_branch, { buffer = prompt_bufnr, nowait = true })
      vim.keymap.set('n', '<C-r>', clear_remembered_branch, { buffer = prompt_bufnr, nowait = true })

      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        local branch = entry and (entry.value or entry[1]) or nil
        if not branch or branch == '' then
          return
        end

        local diff_ref = branch
        local files = list_changed_files(root, diff_ref)
        if #files == 0 then
          notify('No changed files found against ' .. diff_ref .. '.', vim.log.levels.INFO)
          set_state(root, {}, 0, diff_ref)
          return
        end

        state.last_branch = branch
        apply_gitsigns_base(diff_ref, true)
        open_changed_files_picker(root, files, diff_ref, 'Changed vs ' .. diff_ref)
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

function M.clear_compare_base()
  state.diff_ref = nil
  state.last_branch = nil
  apply_gitsigns_base(nil, true)
  notify('Reset compare base and cleared remembered branch.')
end

return M
