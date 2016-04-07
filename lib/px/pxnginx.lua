----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.0
-- Release date: 21.02.2015
----------------------------------------------

local pxFilters = require "px.utils.pxfilters"
local pxClient = require "px.utils.pxclient"
local pxChallengeCheck = require "px.challenge.pxchallenge_check"
local pxBlockCheck = require "px.block.pxblock_check"

if (pxFilters.Process()) then
    return 0
end

if (pxChallengeCheck.Process()) then
    return 1
end

if (pxBlockCheck.Process()) then
    return 2
end

ngx.log(ngx.ERR, "send page request activity")
pxClient.sendActivityTo_Perimeter("page_requested")

return 0
