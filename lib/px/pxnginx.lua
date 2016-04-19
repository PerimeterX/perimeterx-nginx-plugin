----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.0
-- Release date: 21.02.2015
----------------------------------------------

local px_filters = require "px.utils.pxfilters"
local px_config = require "px.pxconfig"
local px_client = require "px.utils.pxclient"
local px_cookie = require "px.utils.pxcookie"
local px_block = require "px.block.pxblock"
local px_api = require "px.utils.pxapi"
local auth_token = px_config.auth_token
local enable_server_calls = px_config.enable_server_calls
local risk_api_path = px_config.risk_api_path
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local ngx_HTTP_FORBIDDEN = ngx.HTTP_FORBIDDEN
local ngx_say = ngx.say
local ngx_exit = ngx.exit
local ngx_OK = ngx.OK
local pcall = pcall

if (px_filters.process()) then
    return true;
end

-- process _px cookie if present
local _px = ngx.var.cookie__px;
local success, result = pcall(px_cookie.process, _px)
px_client.send_to_perimeterx("page_requested")

-- cookie verification passed - checking result.
if success then
    -- score crossed threshold
    if result == false then
        px_block.block('cookie_high_score')
        -- score did not cross the blocking threshold
    else
        px_client.send_to_perimeterx("page_requested")
        return true
    end
    -- cookie verification failed/cookie does not exist. performing s2s query
elseif enable_server_calls == true then
    local request_data = px_api.new_request_object()
    local success, response = pcall(px_api.call_s2s, request_data, risk_api_path, auth_token)
    local result
    if success then
        result = px_api.process(response);
        -- score crossed threshold
        if result == false then
            px_block.block('s2s_high_score')
            -- score did not cross the blocking threshold
        else
            px_client.send_to_perimeterx("page_requested")
            return true
        end
    else
        -- server2server call failed, passing taffic
        ngx_log(ngx_ERR, "PX: Failed server to server API call - ", result)
        px_client.send_to_perimeterx("page_requested")
        return true
    end
else
    px_client.send_to_perimeterx("page_requested")
    return true
end
