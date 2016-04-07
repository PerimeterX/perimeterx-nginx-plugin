----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.5.0
-- Release date: 05.04.2016
----------------------------------------------
local config = require "px.pxconfig"
local pxclient = require "px.utils.pxclient"
local cjson = require "cjson"

local BLOCK_CHECK = {}

function BLOCK_CHECK.Process()
    local cookie_validity = false


    if (not cookie_validity) then
        return BLOCK_CHECK.retriveScoreFromServer();
    end
end

function BLOCK_CHECK.retriveScoreFromServer()
    local res = pxclient.retriveScoreFromServer()
    ngx.log(ngx.ERR, cjson.encode(res))
    return false;
end
return BLOCK_CHECK