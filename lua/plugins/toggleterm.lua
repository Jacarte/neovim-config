local Terminal  = require('toggleterm.terminal').Terminal
local lazygit = Terminal:new({ cmd = "lazygit", hidden = true, direction="float" })

function _lazygit_toggle()
  lazygit:toggle()
end



local sessionalT = Terminal:new({ hidden = true, direction = "float" })
function _session_toggle()
  sessionalT:toggle()
end

local sessionalTC = Terminal:new({cmd="colima ssh",  hidden = true, direction = "horizontal" })
function _session_colima_toggle()
  sessionalTC:toggle()
end


