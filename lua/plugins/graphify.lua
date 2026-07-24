local M = {}

local config = {
  command = { "graphify", "watch", "." },
  root = nil,
  stop_timeout_ms = 500,
  max_log_lines = 5000,
  log_window_height = 12,
}

local state = {
  process = nil,
  root = nil,

  log_buffer = nil,
  log_lines = {},

  partial = {
    stdout = "",
    stderr = "",
  },

  intentional_stops = {},
}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, {
    title = "Graphify",
  })
end

local function startup_root()
  local first_argument = vim.fn.argv(0)

  -- `nvim .` or `nvim some-directory`
  if first_argument ~= "" and vim.fn.isdirectory(first_argument) == 1 then
    return vim.fs.normalize(
      vim.fn.fnamemodify(first_argument, ":p")
    )
  end

  -- `cd project && nvim`
  return vim.fs.normalize(
    vim.uv.cwd() or vim.fn.getcwd()
  )
end

local function command_as_string()
  local arguments = {}

  for _, argument in ipairs(config.command) do
    table.insert(arguments, tostring(argument))
  end

  return table.concat(arguments, " ")
end

local function trim_logs()
  local excess = #state.log_lines - config.max_log_lines

  if excess <= 0 then
    return
  end

  for _ = 1, excess do
    table.remove(state.log_lines, 1)
  end
end

local function render_logs()
  local buffer = state.log_buffer

  if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
    return
  end

  local display_lines = state.log_lines

  if #display_lines == 0 then
    display_lines = {
      "No graphify output yet.",
    }
  end

  pcall(function()
    vim.bo[buffer].modifiable = true

    vim.api.nvim_buf_set_lines(
      buffer,
      0,
      -1,
      false,
      display_lines
    )

    vim.bo[buffer].modifiable = false
  end)

  -- Keep every visible Graphify log window at the bottom.
  for _, window in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(window) == buffer then
      pcall(
        vim.api.nvim_win_set_cursor,
        window,
        { #display_lines, 0 }
      )
    end
  end
end

local function append_log_lines(lines)
  if not lines or #lines == 0 then
    return
  end

  for _, line in ipairs(lines) do
    table.insert(state.log_lines, line)
  end

  trim_logs()
  render_logs()
end

local function clear_logs()
  state.log_lines = {}

  state.partial = {
    stdout = "",
    stderr = "",
  }

  render_logs()
end

local function format_stream_lines(stream, lines)
  if stream ~= "stderr" then
    return lines
  end

  local formatted = {}

  for _, line in ipairs(lines) do
    table.insert(formatted, "[stderr] " .. line)
  end

  return formatted
end

local function flush_partial_stream(stream)
  local partial = state.partial[stream]

  if not partial or partial == "" then
    return
  end

  state.partial[stream] = ""

  append_log_lines(
    format_stream_lines(stream, { partial })
  )
end

local function flush_partial_output()
  flush_partial_stream("stdout")
  flush_partial_stream("stderr")
end

local function handle_stream_output(stream, err, data)
  if err then
    append_log_lines({
      ("[%s error] %s"):format(stream, tostring(err)),
    })
  end

  -- A nil value indicates that the stream has closed.
  if data == nil then
    flush_partial_stream(stream)
    return
  end

  if data == "" then
    return
  end

  local combined = state.partial[stream] .. data

  local lines = vim.split(combined, "\n", {
    plain = true,
    trimempty = false,
  })

  -- The last item may be an unfinished line.
  state.partial[stream] = table.remove(lines) or ""

  if #lines > 0 then
    append_log_lines(
      format_stream_lines(stream, lines)
    )
  end
end

local function capture_output(stream)
  return function(err, data)
    vim.schedule(function()
      handle_stream_output(stream, err, data)
    end)
  end
end

local function ensure_log_buffer()
  if state.log_buffer
      and vim.api.nvim_buf_is_valid(state.log_buffer) then
    return state.log_buffer
  end

  local buffer = vim.api.nvim_create_buf(false, true)
  state.log_buffer = buffer

  vim.api.nvim_buf_set_name(buffer, "graphify://logs")

  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].bufhidden = "hide"
  vim.bo[buffer].swapfile = false
  vim.bo[buffer].filetype = "log"
  vim.bo[buffer].modifiable = false

  vim.keymap.set("n", "q", "<cmd>close<cr>", {
    buffer = buffer,
    silent = true,
    desc = "Close Graphify logs",
  })

  vim.keymap.set("n", "r", function()
    M.restart()
  end, {
    buffer = buffer,
    silent = true,
    desc = "Restart Graphify",
  })

  vim.keymap.set("n", "c", function()
    M.clear_logs()
  end, {
    buffer = buffer,
    silent = true,
    desc = "Clear Graphify logs",
  })

  return buffer
end

local function find_log_window(buffer)
  for _, window in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(window) == buffer then
      return window
    end
  end

  return nil
end

function M.logs()
  local buffer = ensure_log_buffer()
  local existing_window = find_log_window(buffer)

  if existing_window then
    vim.api.nvim_set_current_win(existing_window)
  else
    vim.cmd(
      ("botright %dsplit"):format(
        config.log_window_height
      )
    )

    vim.api.nvim_win_set_buf(
      vim.api.nvim_get_current_win(),
      buffer
    )
  end

  render_logs()

  local line_count = vim.api.nvim_buf_line_count(buffer)

  pcall(
    vim.api.nvim_win_set_cursor,
    vim.api.nvim_get_current_win(),
    { line_count, 0 }
  )
end

function M.clear_logs()
  clear_logs()
end

function M.start()
  if not vim.system then
    notify(
      "vim.system() is unavailable. Update Neovim.",
      vim.log.levels.ERROR
    )
    return
  end

  if state.process and not state.process:is_closing() then
    notify(
      ("Graphify is already running with PID %d"):format(
        state.process.pid
      )
    )
    return
  end

  if not state.root or vim.fn.isdirectory(state.root) ~= 1 then
    notify(
      "Invalid Graphify root: " .. tostring(state.root),
      vim.log.levels.ERROR
    )
    return
  end

  local executable = config.command[1]

  if not executable or vim.fn.executable(executable) ~= 1 then
    notify(
      "Graphify executable not found: "
        .. tostring(executable),
      vim.log.levels.ERROR
    )
    return
  end

  clear_logs()

  local process

  local ok, result = pcall(function()
    process = vim.system(config.command, {
      cwd = state.root,
      text = true,
      detach = false,
      stdout = capture_output("stdout"),
      stderr = capture_output("stderr"),
    }, function(completed)
      vim.schedule(function()
        flush_partial_output()

        local intentional =
          state.intentional_stops[process] == true

        state.intentional_stops[process] = nil

        append_log_lines({
          "",
          (
            "=== graphify exited: PID=%d code=%d signal=%d ==="
          ):format(
            process.pid,
            completed.code,
            completed.signal
          ),
        })

        if state.process == process then
          state.process = nil
        end

        if not intentional and completed.code ~= 0 then
          notify(
            ("Graphify PID %d exited with code %d"):format(
              process.pid,
              completed.code
            ),
            vim.log.levels.ERROR
          )
        end
      end)
    end)

    return process
  end)

  if not ok then
    append_log_lines({
      "Failed to start graphify:",
      tostring(result),
    })

    notify(
      "Could not start Graphify: " .. tostring(result),
      vim.log.levels.ERROR
    )

    return
  end

  state.process = result

  append_log_lines({
    ("=== graphify started at %s ==="):format(
      os.date("%Y-%m-%d %H:%M:%S")
    ),
    ("PID: %d"):format(result.pid),
    ("Root: %s"):format(state.root),
    ("Command: %s"):format(command_as_string()),
    "",
  })
end

function M.stop(options)
  options = options or {}

  local process = state.process

  if not process then
    if not options.silent then
      notify("Graphify is not running")
    end

    return
  end

  state.intentional_stops[process] = true

  if state.process == process then
    state.process = nil
  end

  append_log_lines({
    "",
    ("Stopping graphify PID %d..."):format(process.pid),
  })

  if process:is_closing() then
    return
  end

  local ok, result = pcall(function()
    process:kill("sigterm")

    -- If SIGTERM does not stop it in time, wait() sends SIGKILL.
    return process:wait(config.stop_timeout_ms)
  end)

  if not ok then
    append_log_lines({
      ("Failed to stop PID %d: %s"):format(
        process.pid,
        tostring(result)
      ),
    })

    if not options.silent then
      notify(
        "Could not stop Graphify: " .. tostring(result),
        vim.log.levels.ERROR
      )
    end
  end
end

function M.restart()
  M.stop({
    silent = true,
  })

  M.start()
end

function M.status()
  local process = state.process

  if process and not process:is_closing() then
    notify(
      ("Running: PID %d, root %s"):format(
        process.pid,
        state.root
      )
    )
  else
    notify(
      ("Not running. Configured root: %s"):format(
        tostring(state.root)
      )
    )
  end
end

function M.setup(options)
  config = vim.tbl_deep_extend(
    "force",
    config,
    options or {}
  )

  state.root = vim.fs.normalize(
    config.root or startup_root()
  )

  vim.api.nvim_create_user_command(
    "GraphifyStart",
    M.start,
    {
      force = true,
      desc = "Start Graphify watcher",
    }
  )

  vim.api.nvim_create_user_command(
    "GraphifyStop",
    function()
      M.stop()
    end,
    {
      force = true,
      desc = "Stop Graphify watcher",
    }
  )

  vim.api.nvim_create_user_command(
    "GraphifyRestart",
    M.restart,
    {
      force = true,
      desc = "Restart Graphify watcher",
    }
  )

  vim.api.nvim_create_user_command(
    "GraphifyStatus",
    M.status,
    {
      force = true,
      desc = "Show Graphify watcher status",
    }
  )

  vim.api.nvim_create_user_command(
    "GraphifyLogs",
    M.logs,
    {
      force = true,
      desc = "Open Graphify logs",
    }
  )

  vim.api.nvim_create_user_command(
    "GraphifyClearLogs",
    M.clear_logs,
    {
      force = true,
      desc = "Clear Graphify logs",
    }
  )

  local group = vim.api.nvim_create_augroup(
    "GraphifyWatch",
    {
      clear = true,
    }
  )

  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    once = true,
    callback = M.start,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.stop({
        silent = true,
      })
    end,
  })

  -- Handle plugin managers that load this module after VimEnter.
  if vim.v.vim_did_enter == 1 then
    vim.schedule(M.start)
  end
end

return M
