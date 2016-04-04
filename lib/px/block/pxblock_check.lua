----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.5.0
-- Release date: 05.04.2016
----------------------------------------------
local config = require "px.pxconfig"

local BLOCK_CHECK = {}

function BLOCK_CHECK.Process()
    return false
end

return BLOCK_CHECK