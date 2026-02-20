local M = {}

local result_buf = nil
local result_win = nil
local input_buf = nil
local input_win = nil
local job_id = nil

local function close_windows()
  if job_id then
    vim.fn.jobstop(job_id)
    job_id = nil
  end
  if input_win and vim.api.nvim_win_is_valid(input_win) then
    vim.api.nvim_win_close(input_win, true)
  end
  if result_win and vim.api.nvim_win_is_valid(result_win) then
    vim.api.nvim_win_close(result_win, true)
  end
  input_win = nil
  result_win = nil
end

local function run_query(question)
  if not result_buf or not vim.api.nvim_buf_is_valid(result_buf) then
    return
  end

  vim.bo[result_buf].modifiable = true
  vim.api.nvim_buf_set_lines(result_buf, 0, -1, false, { "  Running..." })

  local chunks = {}

  job_id = vim.fn.jobstart(
    string.format(
      "opencode run --agent nvim-explorer --model opencode/big-pickle %s",
      vim.fn.shellescape(question)
    ), {
    cwd = vim.fn.expand("~/.config/nvim"),
    pty = true,
    on_stdout = function(_, data)
      if data then
        vim.schedule(function()
          if not result_buf or not vim.api.nvim_buf_is_valid(result_buf) then return end
          for _, line in ipairs(data) do
            local clean = line
              :gsub("\27%[[0-9;]*m", "")
              :gsub("\27%[[%d;]*[ABCDHIJK]", "")
              :gsub("\27%[[^m]*[a-zA-Z]", "")
              :gsub("\27%][^\27]*\27\\", "")
              :gsub("\27%][^\7]*\7", "")
              :gsub("\27[%(%)][A-Z0-9]", "")
              :gsub("\27=", "")
              :gsub("\27>", "")
              :gsub("\r", "")
              :gsub("%s+$", "")
            if clean ~= "" then
              table.insert(chunks, clean)
            end
          end
          vim.bo[result_buf].modifiable = true
          vim.api.nvim_buf_set_lines(result_buf, 0, -1, false, chunks)
          vim.bo[result_buf].modifiable = false
          if result_win and vim.api.nvim_win_is_valid(result_win) then
            local line_count = vim.api.nvim_buf_line_count(result_buf)
            vim.api.nvim_win_set_cursor(result_win, { line_count, 0 })
          end
        end)
      end
    end,
    on_exit = function()
      vim.schedule(function()
        job_id = nil
        if result_buf and vim.api.nvim_buf_is_valid(result_buf) then
          vim.bo[result_buf].modifiable = true
          if #chunks == 0 or (#chunks == 1 and chunks[1] == "") then
            vim.api.nvim_buf_set_lines(result_buf, 0, -1, false, { "  (no output)" })
          end
          vim.bo[result_buf].modifiable = false
        end
      end)
    end,
  })
end

function M.open()
  close_windows()

  local editor_w = vim.o.columns
  local editor_h = vim.o.lines
  local width = math.floor(editor_w * 0.7)
  local height = math.floor(editor_h * 0.7)
  local col = math.floor((editor_w - width) / 2)
  local row = math.floor((editor_h - height) / 2)

  local input_height = 1
  local result_height = height - input_height - 2

  input_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[input_buf].buftype = "nofile"
  vim.bo[input_buf].filetype = "opencode_input"

  input_win = vim.api.nvim_open_win(input_buf, true, {
    relative = "editor",
    width = width,
    height = input_height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " Ask about nvim config ",
    title_pos = "center",
  })

  result_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[result_buf].buftype = "nofile"
  vim.bo[result_buf].filetype = "markdown"
  vim.bo[result_buf].modifiable = false

  result_win = vim.api.nvim_open_win(result_buf, false, {
    relative = "editor",
    width = width,
    height = result_height,
    col = col,
    row = row + input_height + 2,
    style = "minimal",
    border = "rounded",
    title = " Answer ",
    title_pos = "center",
  })

  vim.wo[result_win].wrap = true
  vim.wo[result_win].linebreak = true

  local augroup = vim.api.nvim_create_augroup("opencode_ask", { clear = true })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = augroup,
    callback = function(ev)
      local closed_win = tonumber(ev.match)
      if closed_win == input_win or closed_win == result_win then
        vim.schedule(close_windows)
        vim.api.nvim_del_augroup_by_id(augroup)
      end
    end,
  })

  vim.cmd("startinsert")

  local function submit()
    local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
    local question = table.concat(lines, " ")
    if question == "" then return end
    run_query(question)
  end

  vim.keymap.set("i", "<CR>", function()
    submit()
    vim.cmd("stopinsert")
  end, { buffer = input_buf })

  vim.keymap.set("n", "<CR>", function()
    submit()
  end, { buffer = input_buf })

  vim.keymap.set({ "n", "i" }, "<Esc>", function()
    close_windows()
  end, { buffer = input_buf })

  vim.keymap.set("n", "q", function()
    close_windows()
  end, { buffer = input_buf })

  if result_buf then
    vim.keymap.set("n", "q", function()
      close_windows()
    end, { buffer = result_buf })

    vim.keymap.set("n", "<Esc>", function()
      close_windows()
    end, { buffer = result_buf })
  end
end

return M
