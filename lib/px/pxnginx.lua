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
    local result, code = px_cookie.process(_px)
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
local data = px_api.new_request_object()
-- TODO --
-- generate and set the CID --
data.cid = 'this is my test cid'
local response = px_api.call_s2s(data, risk_api_path, auth_token)
local result =  px_api.process(response)

if result == true then
    px_client.send_to_perimeterx("page_requested")
    return true
end
-- TODO --
-- Handle S2S response with more logic
-- DO CHALLENGE --
px_challenge.challenge() -- block

-- Catch all --
ngx.status = ngx_HTTP_FORBIDDEN
ngx_say("You shoud never get here")
ngx_exit(ngx_OK)

