local Terminal  = require('toggleterm.terminal').Terminal
function _lazygit_toggle()
  Terminal:new({ cmd = "lazygit", hidden = true, direction="float" }):toggle()
end

local terminals = {}
local current_index = 1

function _session_toggle()
  local count = vim.v.count

  if count == 0 then
    if #vim.tbl_keys(terminals) == 0 then
      count = 1
    else
      local keys = vim.tbl_keys(terminals)
      table.sort(keys)

      local next_index = nil
      for _, key in ipairs(keys) do
        if key > current_index then
          next_index = key
          break
        end
      end

      current_index = next_index or keys[1]
      count = current_index
    end
  else
    current_index = count
  end

  local term = terminals[count]

  if term and term.bufnr and vim.api.nvim_buf_is_valid(term.bufnr) then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == term.bufnr then
        vim.api.nvim_win_close(win, true)
        return
      end
    end
    vim.cmd("vsplit")
    vim.api.nvim_win_set_buf(0, term.bufnr)
    vim.cmd("startinsert")
    return
  end

  vim.cmd("vsplit | terminal")
  local bufnr = vim.api.nvim_get_current_buf()
  terminals[count] = { bufnr = bufnr }
  vim.cmd("startinsert")
end

local function get_active_term_chan()
  for _, term in pairs(terminals) do
    if term.bufnr and vim.api.nvim_buf_is_valid(term.bufnr) then
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == term.bufnr then
          local chan = vim.bo[term.bufnr].channel
          if chan and chan > 0 then
            return chan
          end
        end
      end
    end
  end
  return nil
end

function _send_selection_to_term()
  local chan = get_active_term_chan()
  if not chan then
    vim.notify("No visible terminal", vim.log.levels.WARN)
    return
  end
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.fn.getline(start_pos[2], end_pos[2])
  for _, line in ipairs(lines) do
    vim.fn.chansend(chan, line .. "\n")
  end
end

function _send_filepath_to_term()
  local chan = get_active_term_chan()
  if not chan then
    vim.notify("No visible terminal", vim.log.levels.WARN)
    return
  end
  vim.fn.chansend(chan, vim.fn.expand("%:p") .. "\n")
end

function _hide_all_terminals()
  for _, term in pairs(terminals) do
    if term.bufnr and vim.api.nvim_buf_is_valid(term.bufnr) then
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == term.bufnr then
          vim.api.nvim_win_close(win, true)
        end
      end
    end
  end
end

function _for_voice()
  local cwd = vim.fn.expand('%:p:h')

end

function _fork_terminal()
  -- Get the current file's working directory
  local cwd = vim.fn.expand('%:p:h')

  -- Prompt the user for a command
  vim.ui.input({ prompt = "Enter command: ", default = "ls" }, function(command)
    if command == nil or command == "" then
      print("No command entered, aborting.")
      return
    end

    -- Define the Kitty command
    local terminal_cmd = string.format("kitty --working-directory='%s' $SHELL -c -l -i '%s; exec $SHELL -l -i'", cwd, command)

    -- Execute the terminal command
    vim.fn.jobstart(terminal_cmd, { detach = true })
  end)
end

function _fork_in()
-- Get the current file's working directory
  local cwd = vim.fn.expand('%:p:h')

  -- Get the default shell from the user's environment
  local shell = vim.fn.getenv("SHELL") or "/bin/bash"

  -- Prompt the user for a command
  vim.ui.input({ prompt = "Enter command: ", default = "" }, function(command)
    if command == nil then
      print("Command input was canceled.")
      return
    end

    -- If no command is given, open an interactive shell
    if command == "" then
      command = shell
    end

    -- Kitty command to open a new tab in the same session
    local terminal_cmd = string.format("kitty @ launch --to unix:/tmp/kitten --type=tab --cwd '%s' $SHELL -c -l -i '%s; exec $SHELL -l -i'", cwd, command)

    -- Execute the command
    vim.fn.jobstart(terminal_cmd, { detach = true })
  end)
end

local sessionalTC = Terminal:new({cmd="colima ssh",  hidden = true, direction = "horizontal" })
function _session_colima_toggle()
  sessionalTC:toggle()
end


