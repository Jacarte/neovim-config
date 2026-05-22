local builtin = require('telescope.builtin')

local M = {}

local last_picker_type = nil

local function open_fresh(picker_type, opts, picker_fn)
  last_picker_type = picker_type
  return picker_fn(opts)
end

local function resume_or_open(picker_type, opts, picker_fn)
  if last_picker_type == picker_type then
    local ok = pcall(builtin.resume)
    if ok then
      return
    end
  end

  return open_fresh(picker_type, opts, picker_fn)
end

function M.find_files(opts)
  return resume_or_open('find_files', opts, builtin.find_files)
end

function M.live_grep(opts)
  return resume_or_open('live_grep', opts, builtin.live_grep)
end

return M
