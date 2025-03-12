local Terminal  = require('toggleterm.terminal').Terminal
function _lazygit_toggle()
  Terminal:new({ cmd = "lazygit", hidden = true, direction="float" }):toggle()
end

local terminals = {}
local current_index = 1 -- Keeps track of the current terminal when iterating

function _session_toggle()
  local count = vim.v.count

  if count == 0 then
    -- If no count is provided, iterate over terminals
    if #vim.tbl_keys(terminals) == 0 then
      count = 1 -- Start from 1 if no terminal exists
    else
      -- Get the list of terminal indices and sort them
      local keys = vim.tbl_keys(terminals)
      table.sort(keys)

      -- Find the next terminal index
      local next_index = nil
      for i, key in ipairs(keys) do
        if key > current_index then
          next_index = key
          break
        end
      end

      -- If no next index, wrap around to the first one
      current_index = next_index or keys[1]
      count = current_index
    end
  else
    -- If count is provided, use it directly
    current_index = count
  end

  -- If a terminal for this count doesn't exist, create one
  if not terminals[count] then
    terminals[count] = Terminal:new({ hidden = true, direction = "float", on_open = function(term)
        term:send("echo 'Terminal #" .. count .. "'\n")
      end })
  end

  -- Toggle the specific terminal instance
  terminals[count]:toggle()
end

function _hide_all_terminals()
  for _, term in pairs(terminals) do
      if term:is_open() then
        term:toggle()
      end
  end
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
    local terminal_cmd = string.format("kitty --working-directory='%s' $SHELL -c '%s; exec $SHELL'", cwd, command)

    -- Execute the terminal command
    vim.fn.jobstart(terminal_cmd, { detach = true })
  end)
end


local sessionalTC = Terminal:new({cmd="colima ssh",  hidden = true, direction = "horizontal" })
function _session_colima_toggle()
  sessionalTC:toggle()
end


