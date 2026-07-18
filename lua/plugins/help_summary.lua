local M = {}
local default_config = {
  trigger_key = "<leader>?",
  floating_patterns = {
    "opencode",
    "snacks",
  },
  max_width = 72,
  max_height = 40,
  auto_attach_floating = true,
  sections = {
    {
      title = "General",
      entries = {
        { key = "<leader>?", desc = "Show this help summary" },
      },
    },
  },
}

local state = {
  config = vim.deepcopy(default_config),
  popup_buf = nil,
  popup_win = nil,
  augroup = nil,
}

local function current_config()
  return state.config
end

local function render_help_lines(entries)
  local lines = {}

  for _, section in ipairs(entries) do
    table.insert(lines, string.format("%s", section.title))
    local row_has_entry = false

    for _, entry in ipairs(section.entries) do
      row_has_entry = true
      table.insert(lines, string.format("  %-14s %s", entry.key, entry.desc))
    end

    if row_has_entry then
      table.insert(lines, "")
    end
  end

  if #lines > 0 and lines[#lines] == "" then
    table.remove(lines, #lines)
  end

  return lines
end

local function buffer_name_or_filetype_matches(bufnr, pattern)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local ft = vim.bo[bufnr].filetype

  return (name ~= nil and name:match(pattern) ~= nil)
    or (ft ~= nil and ft ~= "" and ft:match(pattern) ~= nil)
end

local function is_plugin_floating_window(winid)
  if type(winid) ~= "number" then
    return false
  end

  if not vim.api.nvim_win_is_valid(winid) then
    return false
  end

  local cfg = vim.api.nvim_win_get_config(winid)
  if cfg == nil or not cfg.relative or cfg.relative == "" then
    return false
  end

  local bufnr = vim.api.nvim_win_get_buf(winid)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  for _, pattern in ipairs(current_config().floating_patterns) do
    if buffer_name_or_filetype_matches(bufnr, pattern) then
      return true
    end
  end

  local bt = vim.bo[bufnr].buftype
  local name = vim.api.nvim_buf_get_name(bufnr)
  return bt == "terminal" and name:find("opencode", 1, true) ~= nil
end

local function close_popup()
  if state.popup_win ~= nil and vim.api.nvim_win_is_valid(state.popup_win) then
    vim.api.nvim_win_close(state.popup_win, true)
  end

  if state.popup_buf ~= nil and vim.api.nvim_buf_is_valid(state.popup_buf) then
    vim.api.nvim_buf_delete(state.popup_buf, { force = true })
  end

  state.popup_win = nil
  state.popup_buf = nil
end

function M.close()
  close_popup()
end

function M.open()
  local config = current_config()
  local lines = render_help_lines(config.sections)

  if #lines == 0 then
    vim.notify("No help lines configured", vim.log.levels.INFO)
    return
  end

  close_popup()

  local max_line_width = 0
  for _, line in ipairs(lines) do
    if #line > max_line_width then
      max_line_width = #line
    end
  end

  local width = math.min(config.max_width, math.max(30, max_line_width + 4))
  local height = math.min(config.max_height, #lines + 2)
  local ui = vim.api.nvim_list_uis()[1]

  if ui == nil then
    for _, line in ipairs(lines) do
      vim.notify(line, vim.log.levels.INFO)
    end
    return
  end

  local row = math.max(1, math.floor((ui.height - height) / 2))
  local col = math.max(1, math.floor((ui.width - width) / 2))

  local popup_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, lines)
  vim.bo[popup_buf].modifiable = false
  vim.bo[popup_buf].buftype = "nofile"
  vim.bo[popup_buf].swapfile = false

  local popup_win = vim.api.nvim_open_win(popup_buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    border = "rounded",
    focusable = true,
    noautocmd = true,
    style = "minimal",
    zindex = 200,
  })

  vim.api.nvim_win_set_option(popup_win, "winhl", "Normal:NormalFloat,FloatBorder:FloatBorder")

  vim.keymap.set("n", "q", M.close, { buffer = popup_buf, nowait = true, silent = true, desc = "Close plugin help" })
  vim.keymap.set("n", "<Esc>", M.close, { buffer = popup_buf, nowait = true, silent = true, desc = "Close plugin help" })
  vim.keymap.set("n", "<CR>", M.close, { buffer = popup_buf, nowait = true, silent = true, desc = "Close plugin help" })

  state.popup_buf = popup_buf
  state.popup_win = popup_win
end

local function attach_window_mapping(winid)
  if type(winid) ~= "number" then
    return
  end

  if not is_plugin_floating_window(winid) then
    return
  end

  local bufnr = vim.api.nvim_win_get_buf(winid)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  vim.keymap.set(
    "n",
    current_config().trigger_key,
    function()
      M.open()
    end,
    { buffer = bufnr, nowait = true, silent = true, desc = "Show plugin help" }
  )
end

function M.setup(opts)
  state.config = vim.tbl_deep_extend("force", default_config, opts or {})

  if opts and opts.sections then
    state.config.sections = opts.sections
  end

  if state.augroup == nil then
    state.augroup = vim.api.nvim_create_augroup("PluginHelpSummary", { clear = true })
  else
    vim.api.nvim_clear_autocmds({ group = state.augroup })
  end

  vim.keymap.set("n", state.config.trigger_key, M.open, { nowait = true, silent = true, desc = "Show plugin help summary" })
  vim.keymap.set("v", state.config.trigger_key, M.open, { nowait = true, silent = true, desc = "Show plugin help summary" })

  if state.config.auto_attach_floating then
    vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
      group = state.augroup,
      callback = function()
        local winid = vim.api.nvim_get_current_win()
        attach_window_mapping(winid)
      end,
    })
  end
end

return M
