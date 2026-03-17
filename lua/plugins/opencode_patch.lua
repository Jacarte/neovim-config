local M = {}

local function read_file(path)
  if vim.fn.filereadable(path) == 0 then
    return nil
  end
  return table.concat(vim.fn.readfile(path), "\n")
end

local function write_file(path, content)
  vim.fn.writefile(vim.split(content, "\n", { plain = true }), path)
end

local function replace_once(content, old, new)
  local next_content, count = content:gsub(vim.pesc(old), new, 1)
  return next_content, count == 1
end

function M.apply(install_path)
  local root = install_path or (vim.fn.stdpath("data") .. "/site/pack/packer/start/opencode.nvim")
  local target = root .. "/lua/opencode/terminal.lua"
  local content = read_file(target)

  if not content then
    return false
  end

  local changed = false

  local helper = [[
local function hide_or_replace_window(window)
  if #vim.api.nvim_tabpage_list_wins(0) > 1 then
    vim.api.nvim_win_hide(window)
    return
  end

  local current_buf = vim.api.nvim_win_get_buf(window)
  local alt_buf = vim.fn.bufnr("#")

  if alt_buf > 0 and alt_buf ~= current_buf and vim.api.nvim_buf_is_valid(alt_buf) then
    vim.api.nvim_win_set_buf(window, alt_buf)
    return
  end

  local fallback_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(window, fallback_buf)
end
]]

  if not content:find("local function hide_or_replace_window", 1, true) then
    local anchor = "local winid\nlocal bufnr"
    local next_content, ok = replace_once(content, anchor, anchor .. "\n\n" .. helper)
    if ok then
      content = next_content
      changed = true
    end
  end

  if not content:find("<C%-Esc>", 1, false) then
    local esc_anchor = [[  end, vim.tbl_extend("force", opts, { desc = "Interrupt current session (esc)" }))]]
    local esc_extra = [[

  vim.keymap.set({ "n", "t" }, "<C-Esc>", function()
    require("opencode").command("session.interrupt")
  end, vim.tbl_extend("force", opts, { desc = "Interrupt current session (ctrl+esc)" }))

  vim.keymap.set("t", "<C-[>", function()
    require("opencode").command("session.interrupt")
  end, vim.tbl_extend("force", opts, { desc = "Interrupt current session (ctrl+[)" }))]]
    local next_content, ok = replace_once(content, esc_anchor, esc_anchor .. esc_extra)
    if ok then
      content = next_content
      changed = true
    end
  end

  if content:find("vim.api.nvim_win_hide%(winid%)", 1, false) then
    local next_content, ok = replace_once(content, "      vim.api.nvim_win_hide(winid)", "      hide_or_replace_window(winid)")
    if ok then
      content = next_content
      changed = true
    end
  end

  if content:find("vim.api.nvim_win_close%(winid, true%)", 1, false)
    and not content:find("if #vim.api.nvim_tabpage_list_wins%(0%) > 1 then", 1, false) then
    local old = "    vim.api.nvim_win_close(winid, true)"
    local new = [[    if #vim.api.nvim_tabpage_list_wins(0) > 1 then
      vim.api.nvim_win_close(winid, true)
    else
      hide_or_replace_window(winid)
    end]]
    local next_content, ok = replace_once(content, old, new)
    if ok then
      content = next_content
      changed = true
    end
  end

  if changed then
    write_file(target, content)
  end

  return changed
end

return M
