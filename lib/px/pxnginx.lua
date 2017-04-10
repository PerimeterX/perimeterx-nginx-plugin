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

local M = {}

function M.application(file_name)
    local _M = {}
    -- Support for multiple apps - each app file should be named "pxconfig-<appname>.lua"
    local config_file = ((file_name == nil or file_name == '') and "px.pxconfig" or "px.pxconfig-" .. file_name)

    local px_config = require(config_file)
    local px_filters = require("px.utils.pxfilters").load(config_file)
    local px_client = require("px.utils.pxclient").load(config_file)
    local px_cookie_v1 = require("px.utils.pxcookie_v1").load(config_file)
    local px_cookie_v3 = require("px.utils.pxcookie_v3").load(config_file)
    local px_captcha = require("px.utils.pxcaptcha").load(config_file)
    local px_block = require("px.block.pxblock").load(config_file)
    local px_api = require("px.utils.pxapi").load(config_file)
    local px_logger = require("px.utils.pxlogger").load(config_file)
    local px_headers = require("px.utils.pxheaders").load(config_file)
    local px_constants = require("px.utils.pxconstants")

    local auth_token = px_config.auth_token
    local enable_server_calls = px_config.enable_server_calls
    local risk_api_path = px_constants.RISK_PATH
    local enabled_routes = px_config.enabled_routes
    local remote_addr = ngx.var.remote_addr or ""
    local user_agent = ngx.var.http_user_agent or ""
    local string_sub = string.sub
    local string_len = string.len
    local pcall = pcall

    local function perform_s2s(result, details)
        local request_data = px_api.new_request_object(result.message)
        local success, response = pcall(px_api.call_s2s, request_data, risk_api_path, auth_token)
        local result
        if success then
            result = px_api.process(response)
            -- score crossed threshold
            if result == false then
                px_logger.error("blocking s2s")
                return px_block.block('s2s_high_score')
                -- score did not cross the blocking threshold
            else
                px_client.send_to_perimeterx("page_requested", details)
                return true
            end
        else
            -- server2server call failed, passing traffic
            px_client.send_to_perimeterx("page_requested", details)
            return true
        end
    end

    if not px_config.px_enabled then
        return true
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
        return true
    end

    -- Validate if request is from internal redirect to avoid duplicate processing
    if px_headers.validate_internal_request() then
        return true
    end

    -- Clean any protected headers from the request.
    -- Prevents header spoofing to upstream application
    px_headers.clear_protected_headers()


    -- run filter and whitelisting logic
    if (px_filters.process()) then
        px_headers.set_score_header(0)
        return true
    end

    px_logger.debug("New request process. IP: " .. remote_addr .. ". UA: " .. user_agent)
    -- process _pxCaptcha cookie if present
    local _pxCaptcha = ngx.var.cookie__pxCaptcha

    if px_config.captcha_enabled and _pxCaptcha then
        local success, result = pcall(px_captcha.process, _pxCaptcha)

        -- validating captcha value and if reset was successful then pass the request
        if success and result == 0 then
            ngx.header["Content-Type"] = nil
            ngx.header["Set-Cookie"] = "_pxCaptcha=; Expires=Thu, 01 Jan 1970 00:00:00 GMT;"
            return true
        end
    end

    local details = {};
    -- process _px cookie v3 if present
    local _px3 = ngx.var.cookie__px3
    local _px = ngx.var.cookie__px

    if _px3 then
        ngx.ctx.px_orig_cookie = _px3
        local success, result = pcall(px_cookie_v3.process, _px3)
        -- cookie verification passed - checking result.
        if success then
            px_logger.debug("PX-CookieV3 Processed Succesfuly")
            details["px_cookie"] = ngx.ctx.px_cookie;
            details["px_cookie_hmac"] = ngx.ctx.px_cookie_hmac;
            details["px_cookie_version"] = 'v3';
            -- score crossed threshold
            if result == false then
                return px_block.block('cookie_high_score')
                -- score did not cross the blocking threshold
            else
                px_client.send_to_perimeterx("page_requested", details)
                return true
            end
            -- cookie verification failed/cookie does not exist. performing s2s query
        elseif enable_server_calls == true then
            return perform_s2s(result, details)
        else
            px_client.send_to_perimeterx("page_requested", details)
            return true
        end
    else
        -- process _px cookie v1
        ngx.ctx.px_orig_cookie = _px
        local success, result = pcall(px_cookie_v1.process, _px)
        local details = {};
        -- cookie verification passed - checking result.
        if success then
            px_logger.debug("PX-CookieV1 Processed Succesfuly")
            details["px_cookie"] = ngx.ctx.px_cookie;
            details["px_cookie_hmac"] = ngx.ctx.px_cookie_hmac;
            details["px_cookie_version"] = 'v1';
            -- score crossed threshold
            if result == false then
                ngx.ctx.px_action = 'c'
                return px_block.block('cookie_high_score')
                -- score did not cross the blocking threshold
            else
                px_client.send_to_perimeterx("page_requested", details)
                return true
            end
            -- cookie verification failed/cookie does not exist. performing s2s query
        elseif enable_server_calls == true then
            return perform_s2s(result, details)
        else
            px_client.send_to_perimeterx("page_requested", details)
            return true
        end
    end
end

return M
