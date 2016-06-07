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
local px_logger = require "px.utils.pxlogger"
local auth_token = px_config.auth_token
local enable_server_calls = px_config.enable_server_calls
local risk_api_path = px_config.risk_api_path
local pcall = pcall

if not px_config.px_enabled then
    return true;
end

local enabled_routes = px_config.enabled_routes
local valid_route = false
-- Enable module only on configured routes
for i = 1, #enabled_routes do
    if string.sub(ngx.var.uri, 1, string.len(enabled_routes[i])) == enabled_routes[i] then
        px_logger.debug("Whitelisted: uri_prefixes. " .. enabled_routes[i])
        valid_route = true
    end
end

if not valid_route then
    ngx.req.set_header(px_config.score_header_name, 0)
    return true;
end

-- skip internal redirect processing
local px_process = ngx.req.get_headers()['px_process']
if px_process and px_process == px_config.cookie_secret then
    px_logger.debug('Internal redirect detected, exit px processing')
    return true
end
ngx.req.set_header('px_process', px_config.cookie_secret)

-- run filter and whitelisting logic
if (px_filters.process()) then
    ngx.req.set_header(px_config.score_header_name, 0)
    return true;
end

px_logger.debug("New request process. IP: " .. ngx.var.remote_addr .. ". UA: " .. ngx.var.http_user_agent)
-- process _px cookie if present
local _px = ngx.var.cookie__px;
local success, result = pcall(px_cookie.process, _px)

-- cookie verification passed - checking result.
if success then
    -- score crossed threshold
    if result == false then
        return px_block.block('cookie_high_score', ngx.ctx.uuid, ngx.ctx.block_score)
        -- score did not cross the blocking threshold
    else
        px_client.send_to_perimeterx("page_requested")
        return true
    end
    -- cookie verification failed/cookie does not exist. performing s2s query
elseif enable_server_calls == true then
    local request_data = px_api.new_request_object(result.message)
    local success, response = pcall(px_api.call_s2s, request_data, risk_api_path, auth_token)
    local result
    if success then
        result = px_api.process(response);
        -- score crossed threshold
        if result == false then
            return px_block.block('s2s_high_score', ngx.ctx.uuid, ngx.ctx.block_score)
            -- score did not cross the blocking threshold
        else
            px_client.send_to_perimeterx("page_requested")
            return true
        end
    else
        -- server2server call failed, passing taffic
        px_client.send_to_perimeterx("page_requested")
        return true
    end
else
    px_client.send_to_perimeterx("page_requested")
    return true
end
