-- Copyright © 2016 PerimeterX, Inc.

-- Permission is hereby granted, free of charge, to any
-- person obtaining a copy of this software and associated
-- documentation files (the "Software"), to deal in the
-- Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the
-- Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice
-- shall be included in all copies or substantial portions of
-- the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
-- KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
-- WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
-- OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
-- OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


local px_filters = require "px.utils.pxfilters"
local px_config = require "px.pxconfig"
local px_client = require "px.utils.pxclient"
local px_cookie = require "px.utils.pxcookie"
local px_captcha = require "px.utils.pxcaptcha"
local px_block = require "px.block.pxblock"
local px_api = require "px.utils.pxapi"
local px_logger = require "px.utils.pxlogger"
local px_headers = require "px.utils.pxheaders"
local auth_token = px_config.auth_token
local enable_server_calls = px_config.enable_server_calls
local risk_api_path = px_config.risk_api_path
local enabled_routes = px_config.enabled_routes
local remote_addr = ngx.var.remote_addr or ""
local user_agent = ngx.var.http_user_agent or ""
local string_sub = string.sub
local string_len = string.len
local pcall = pcall

if not px_config.px_enabled then
    return true;
end

local valid_route = false

-- Enable module only on configured routes
for i = 1, #enabled_routes do
    if string_sub(ngx.var.uri, 1, string_len(enabled_routes[i])) == enabled_routes[i] then
        px_logger.debug("Checking for enabled routes. " .. enabled_routes[i])
        valid_route = true
    end
end

if not valid_route and #enabled_routes > 0 then
    px_headers.set_score_header(0)
    return true;
end

-- Validate if request is from internal redirect to avoid duplicate processing
if px_headers.validate_internal_request() then
    return true;
end

-- Clean any protected headers from the request.
-- Prevents header spoofing to upstream application
px_headers.clear_protected_headers()


-- run filter and whitelisting logic
if (px_filters.process()) then
    px_headers.set_score_header(0)
    return true;
end

px_logger.debug("New request process. IP: " .. remote_addr .. ". UA: " .. user_agent)
-- process _px cookie if present
local _px = ngx.var.cookie__px;
local _pxCaptcha = ngx.var.cookie__pxCaptcha;

if px_config.captcha_enabled then
    local success, result = pcall(px_captcha.process, _pxCaptcha)

    -- validating captcha value and if reset went well, pass traffic
    if success and result == 0 then
        return true;
    end
end

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
            px_logger.error("blocking s2s")
            return px_block.block('s2s_high_score', ngx.ctx.uuid, ngx.ctx.block_score)
            -- score did not cross the blocking threshold
        else
            px_client.send_to_perimeterx("page_requested")
            return true
        end
    else
        -- server2server call failed, passing traffic
        px_client.send_to_perimeterx("page_requested")
        return true
    end
else
    px_client.send_to_perimeterx("page_requested")
    return true
end
