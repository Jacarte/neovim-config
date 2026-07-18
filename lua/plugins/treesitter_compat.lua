local M = {}

local function normalize_nodes(capture)
  if capture == nil then
    return {}
  end

  if vim.islist(capture) then
    return capture
  end

  return { capture }
end

local function has_ancestor(match, _pattern, _bufnr, pred)
  if pred[2] == nil then
    return nil
  end

  local nodes = normalize_nodes(match[pred[2]])
  if #nodes == 0 then
    return true
  end

  local ancestor_types = { unpack(pred, 3) }
  local just_direct_parent = pred[1]:find("has-parent", 1, true) ~= nil

  for _, node in ipairs(nodes) do
    local parent = node and node:parent() or nil
    while parent do
      if vim.tbl_contains(ancestor_types, parent:type()) then
        return true
      end

      if just_direct_parent then
        break
      end

      parent = parent:parent()
    end
  end

  return false
end

function M.apply()
  local query = require('vim.treesitter.query')
  local opts = vim.fn.has('nvim-0.10') == 1 and { force = true, all = true } or true

  query.add_predicate('has-ancestor?', has_ancestor, opts)
  query.add_predicate('has-parent?', has_ancestor, opts)
end

return M
