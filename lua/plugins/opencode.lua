require("plugins.opencode_patch").apply()

do
  local ok_snacks, snacks = pcall(require, "snacks")
  if ok_snacks and snacks and snacks.setup and snacks.config and snacks.config.get then
    local input_cfg = snacks.config.get("input", {})
    if input_cfg.enabled ~= true then
      snacks.setup({
        input = { enabled = true },
        picker = {
          actions = {
            opencode_send = function(...) return require("opencode").snacks_picker_send(...) end,
          },
          win = {
            input = {
              keys = {
                ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
              },
            },
          },
        },
      })
    end
  end
end

local workdir = vim.fn.getcwd(-1, -1)
local workdir_hash = vim.fn.sha256(workdir)
local workdir_leaf = vim.fn.fnamemodify(workdir, ":t")
workdir_leaf = workdir_leaf:gsub("[^%w_%-]", "-")
if workdir_leaf == "" then
  workdir_leaf = "root"
end

local tmux_session = string.format("opencode-%s-%s", workdir_leaf, workdir_hash:sub(1, 8))
local opencode_port = 20000 + (tonumber(workdir_hash:sub(1, 6), 16) % 20000)
local opencode_cmd = string.format("opencode --port %d", opencode_port)

local function tmux_has_session()
  local out = vim.fn.system({ "tmux", "has-session", "-t", tmux_session })
  return vim.v.shell_error == 0 and out == ""
end

local function tmux_start()
  if tmux_has_session() then
    return
  end

  vim.fn.jobstart({ "tmux", "new-session", "-d", "-s", tmux_session, opencode_cmd }, { detach = true })
end

local function tmux_stop()
  if not tmux_has_session() then
    return
  end

  vim.fn.jobstart({ "tmux", "kill-session", "-t", tmux_session }, { detach = true })
end

local function focus_opencode_attach_window()
  local needle = "tmux attach -t " .. tmux_session
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "terminal" then
      local name = vim.api.nvim_buf_get_name(buf)
      if name:find(needle, 1, true) ~= nil then
        vim.api.nvim_set_current_win(win)
        vim.cmd("startinsert")
        return true
      end
    end
  end

  return false
end

local function ensure_opencode_server_connection()
  local ok_server, server = pcall(require, "opencode.cli.server")
  if not ok_server or not server or not server.get then
    return
  end

  local ok_get, promise = pcall(server.get, false)
  if ok_get and promise and promise.catch then
    promise:catch(function()
      return nil
    end)
  end
end

local function tmux_toggle()
  -- Prefer tmux sessions so the opencode process survives terminal toggles,
  -- but keep a plain terminal fallback for machines without tmux installed.
  local ok_terminal, terminal = pcall(require, "opencode.terminal")
  local has_tmux_bin = vim.fn.executable("tmux") == 1
  if not has_tmux_bin then
    if ok_terminal and terminal and terminal.toggle then
      terminal.toggle(opencode_cmd)
      vim.schedule(function()
        focus_opencode_attach_window()
        ensure_opencode_server_connection()
      end)
    end
    return
  end

  if not tmux_has_session() then
    -- Lazily create the per-workdir tmux session on first use.
    tmux_start()
    if not tmux_has_session() then
      vim.notify(string.format("Could not create tmux session '%s' for this workdir.", tmux_session), vim.log.levels.ERROR)
      return
    end
  end

  if vim.env.TMUX and vim.env.TMUX ~= "" then
    -- Inside tmux: open a popup attached to the existing session instead of
    -- nesting terminal buffers, which keeps input/focus behavior predictable.
    if ok_terminal and terminal and terminal.stop then
      pcall(terminal.stop)
    end

    local popup_cmd = string.format("sh -lc \"tmux attach -t %s\"", tmux_session)

    vim.fn.jobstart({
      "tmux",
      "display-popup",
      "-E",
      "-w",
      "90%",
      "-h",
      "85%",
      popup_cmd,
    }, { detach = true })
    vim.schedule(function()
      ensure_opencode_server_connection()
    end)
  else
    -- Outside tmux: attach through the plugin terminal so Neovim users get a
    -- consistent toggle workflow from the editor.
    local attach_cmd = string.format("sh -lc \"tmux attach -t %s\"", tmux_session)

    if ok_terminal and terminal and terminal.toggle then
      terminal.toggle(attach_cmd)
      vim.schedule(function()
        focus_opencode_attach_window()
        ensure_opencode_server_connection()
      end)
      return
    end

    vim.notify(string.format("Attach with: tmux attach -t %s", tmux_session), vim.log.levels.INFO)
  end
end

vim.g.opencode_opts = vim.tbl_deep_extend("force", vim.g.opencode_opts or {}, {
  server = {
    port = opencode_port,
    start = tmux_start,
    stop = tmux_stop,
    toggle = tmux_toggle,
  },
})

local ok_config, opencode_config = pcall(require, "opencode.config")
if ok_config and opencode_config and opencode_config.opts then
  opencode_config.opts.server = vim.tbl_deep_extend("force", opencode_config.opts.server or {}, {
    port = opencode_port,
    start = tmux_start,
    stop = tmux_stop,
    toggle = tmux_toggle,
  })
end

vim.o.autoread = true

local function ask_opencode_current_session(prompt, opts)
  opts = opts or { submit = true }

  if tmux_has_session() then
    require("opencode").ask(prompt, opts)
    return
  end

  require("opencode.cli.server")
    .get(false)
    :next(function(server)
      local Promise = require("opencode.promise")
      return Promise.new(function(resolve)
        require("opencode.cli.client").get_sessions(server.port, function(sessions)
          table.sort(sessions, function(a, b)
            return (a.time and a.time.updated or 0) > (b.time and b.time.updated or 0)
          end)

          if sessions[1] and sessions[1].id then
            require("opencode.cli.client").select_session(server.port, sessions[1].id)
          end

          resolve(true)
        end)
      end)
    end)
    :next(function()
      require("opencode").ask(prompt, opts)
    end)
    :catch(function()
      require("opencode").ask(prompt, opts)
    end)
end

vim.keymap.set({ "n", "x" }, "<C-a>", function()
  ask_opencode_current_session("@this: ", { submit = true })
end, { desc = "Ask opencode..." })

vim.keymap.set({ "n", "x" }, "<C-x>", function()
  require("opencode").select()
end, { desc = "Execute opencode action..." })

pcall(vim.keymap.del, "n", "<C-.>")
pcall(vim.keymap.del, "t", "<C-.>")
vim.keymap.set("n", "<C-.>", function()
  require("opencode").toggle()
end, { desc = "Toggle opencode" })
vim.keymap.set("n", "<leader>oo", function()
  require("opencode").toggle()
end, { desc = "Toggle opencode (fallback)" })

local function is_opencode_terminal_buffer(bufnr)
  if not (bufnr and vim.api.nvim_buf_is_valid(bufnr)) then
    return false
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  local bt = vim.bo[bufnr].buftype
  return bt == "terminal" and name:match("term://.*opencode") ~= nil
end

local focus_guard_group = vim.api.nvim_create_augroup("OpencodeFocusGuard", { clear = true })

vim.api.nvim_create_autocmd("BufEnter", {
  group = focus_guard_group,
  pattern = "*",
  callback = function(ev)
    if is_opencode_terminal_buffer(ev.buf) then
      return
    end

    local target_win = nil
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_buf(win) == ev.buf then
        target_win = win
        break
      end
    end

    if target_win and vim.api.nvim_win_is_valid(target_win) then
      vim.schedule(function()
        if not vim.api.nvim_win_is_valid(target_win) then
          return
        end

        local active_win = vim.api.nvim_get_current_win()
        local active_buf = vim.api.nvim_win_get_buf(active_win)
        if is_opencode_terminal_buffer(active_buf) then
          vim.api.nvim_set_current_win(target_win)
        end
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*opencode*",
  callback = function(ev)
    vim.keymap.set("t", "<C-w>", "<C-\\><C-n><C-w>", { buffer = ev.buf, silent = true })
    vim.keymap.set("t", "<C-.>", function()
      require("opencode").toggle()
    end, { buffer = ev.buf, silent = true, desc = "Toggle opencode" })

    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(ev.buf) then
        local current_buf = vim.api.nvim_get_current_buf()
        if current_buf == ev.buf then
          vim.cmd("startinsert")
        end
      end
    end)
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  group = focus_guard_group,
  pattern = "term://*opencode*",
  callback = function()
    vim.schedule(function()
      local current_buf = vim.api.nvim_get_current_buf()
      if is_opencode_terminal_buffer(current_buf) then
        vim.cmd("startinsert")
      end
    end)
  end,
})

vim.keymap.set({ "n", "x" }, "<leader>go", function()
  return require("opencode").operator("@this ")
end, { desc = "Add range to opencode", expr = true })

vim.keymap.set("n", "<leader>goo", function()
  return require("opencode").operator("@this ") .. "_"
end, { desc = "Add line to opencode", expr = true })

vim.keymap.set("n", "<S-C-u>", function()
  require("opencode").command("session.half.page.up")
end, { desc = "Scroll opencode up" })

vim.keymap.set("n", "<S-C-d>", function()
  require("opencode").command("session.half.page.down")
end, { desc = "Scroll opencode down" })

vim.keymap.set("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })
