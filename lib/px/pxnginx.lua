----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.0
-- Release date: 21.02.2015
----------------------------------------------

local px_filters = require "px.utils.pxfilters"
local px_config = require "px.pxconfig"
local px_client = require "px.utils.pxclient"
local px_cookie = require "px.utils.pxcookie"
local px_challenge = require "px.challenge.pxchallenge"
local px_block = require "px.block.pxblock"
local px_api = require "px.utils.pxapi"
local auth_token = px_config.auth_token
local risk_api_path = px_config.risk_api_path
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local ngx_HTTP_FORBIDDEN = ngx.HTTP_FORBIDDEN
local ngx_say = ngx.say
local ngx_exit = ngx.exit
local ngx_OK = ngx.OK

if (px_filters.process()) then
    return true
end

-- process _px cookie if present
if ngx.var.cookie__px then
    local _px = ngx.var.cookie__px
    local success, result  = pcall(px_cookie.process,_px)
    if not success then
        ngx_log(ngx_ERR,"PX: Failed to process _px cookie - ", result)
        px_block.block()
    end

    if result == true then
        px_client.send_to_perimeterx("page_requested")
        return true
    end

    -- If false block with 403 status code
    px_block.block()
end

if ngx.var.cookie__pxcook then
    local _pxcook = ngx.var.cookie__pxcook
    local result = px_challenge.process(_pxcook)
    -- If false challenge with 503 status code + JS
    if not result then
        px_challenge.challenge()
    end
    return true
end

-- if no _px or _pxcook is present call s2s API --
-- if the s2s fails (timeout or connectivity) then issue JS challenge as fallback
local data = px_api.new_request_object()
local success, result = pcall(px_api.call_s2s,data, risk_api_path, auth_token)
if not success then
    ngx_log(ngx_ERR,"PX: Failed server to server API call - ", result)
    px_challenge.challenge()
end
local response = result

local result =  px_api.process(response)
if result == true then
    px_client.send_to_perimeterx("page_requested")
    return true
else
    -- if s2s returns high, start with challenge --
    px_challenge.challenge()
end

-- Catch all --
px_block.block()
