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
M.configLoaded = false
function M.application(px_configuration_table)
    local config_builder = require("px.utils.config_builder");

    local px_config = config_builder.load(px_configuration_table)
    local _M = {}
    -- Support for multiple apps - each app file should be named "pxconfig-<appname>.lua"
    local px_filters = require("px.utils.pxfilters").load(px_config)
    local px_client = require("px.utils.pxclient").load(px_config)
    local PXPayload = require('px.utils.pxpayload')
    local px_payload = PXPayload:new{}
    local px_captcha = require("px.utils.pxcaptcha").load(px_config)
    local px_block = require("px.block.pxblock").load(px_config)
    local px_api = require("px.utils.pxapi").load(px_config)
    local px_logger = require("px.utils.pxlogger").load(px_config)
    local px_headers = require("px.utils.pxheaders").load(px_config)
    local px_constants = require("px.utils.pxconstants")
    local px_common_utils = require("px.utils.pxcommonutils")

    local auth_token = px_config.auth_token
    local enable_server_calls = px_config.enable_server_calls
    local risk_api_path = px_constants.RISK_PATH
    local enabled_routes = px_config.enabled_routes
    local remote_addr = px_headers.get_ip()
    local user_agent = ngx.var.http_user_agent or ""
    local string_sub = string.sub
    local string_len = string.len
    local pcall = pcall

    local reverse_prefix = string.sub(px_config.px_appId, 3, string.len(px_config.px_appId))
    local lower_request_url = string.lower(ngx.var.request_uri)

    -- Internal wrapper function, will check if uri match first party route and forward the request if uri was matched
    local function is_first_party_request(reverse_prefix, lower_request_url)
        local first_party_flag = false
        if px_client.reverse_px_client(reverse_prefix, lower_request_url) then
            first_party_flag = true
        elseif px_client.reverse_px_xhr(reverse_prefix, lower_request_url) then
            first_party_flag = true
        elseif px_client.reverse_px_captcha(reverse_prefix, lower_request_url) then
            first_party_flag = true
        end
        return first_party_flag
    end

    local function perform_s2s(result, details)
        px_logger.debug("Evaluating Risk API request, call reason: " .. result.message)
        ngx.ctx.s2s_call_reason = result.message
        local request_data = px_api.new_request_object(result.message)
        local start_risk_rtt = px_common_utils.get_time_in_milliseconds()
        local success, response = pcall(px_api.call_s2s, request_data, risk_api_path, auth_token)

        ngx.ctx.risk_rtt = px_common_utils.get_time_in_milliseconds() - start_risk_rtt
	    ngx.ctx.is_made_s2s_api_call = true

        local result
        if success then
            result = px_api.process(response)
            px_logger.debug("Risk API response returned successfully, risk score: ".. ngx.ctx.block_score ..", round_trip_time: " .. ngx.ctx.risk_rtt)
            -- case score crossed threshold
            if not result then
                px_logger.debug("Request will be blocked due to: " .. ngx.ctx.block_reason)
                return px_block.block(ngx.ctx.block_reason)
            end
            -- score did not cross the blocking threshold
            ngx.ctx.pass_reason = 's2s'
            pcall(px_client.send_to_perimeterx, "page_requested", details)
            return true
        else
            -- server2server call failed, passing traffic
            ngx.ctx.pass_reason = 'error'
            if string.match(response,'timeout') then
                px_logger.debug('Risk API timed out - rtt: ' .. ngx.ctx.risk_rtt)
                ngx.ctx.pass_reason = 's2s_timeout'
            end
            px_logger.debug('Risk API failed with error: ' .. response)
            px_client.send_to_perimeterx("page_requested", details)

            return true
        end
    end


    -- Match for client/XHRs/captcha
    if is_first_party_request(reverse_prefix, lower_request_url) then
        return true
    end

    if not px_config.px_enabled then
        px_logger.debug("Request will not be verified, module is disabled")
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

    px_logger.debug("Starting request verification. IP: " .. remote_addr .. ". UA: " .. user_agent)
    -- process _pxCaptcha cookie if present
    local _pxCaptcha = ngx.var.cookie__pxCaptcha
    local details = {};

    if _pxCaptcha then
        local success, result = pcall(px_captcha.process, _pxCaptcha)

        -- validating captcha value and if reset was successful then pass the request
        if success and result == 0 then
            ngx.header["Content-Type"] = nil
            ngx.header["Set-Cookie"] = "_pxCaptcha=; Expires=Thu, 01 Jan 1970 00:00:00 GMT;"
            pcall(px_client.send_to_perimeterx, "page_requested", details)
            return true
        end
    end

    px_payload:load(px_config)
    px_cookie = px_payload:get_payload()
    px_cookie:load(px_config)

    local success, result = pcall(px_cookie.process, px_cookie)
    -- cookie verification passed - checking result.
    if success then
        px_logger.debug("Cookie evaluation ended successfully, risk score: " .. ngx.ctx.block_score)
        details["px_cookie"] = ngx.ctx.px_cookie;
        details["px_cookie_hmac"] = ngx.ctx.px_cookie_hmac;
        details["px_cookie_version"] = ngx.ctx.px_cookie_version;

        px_logger.enrich_log('pxscore', ngx.ctx.block_score)
        px_logger.enrich_log('pxcookiets', ngx.ctx.cookie_timestamp)
        -- score crossed threshold
        if result == false then
            ngx.ctx.block_reason = 'cookie_high_score'
            return px_block.block(ngx.ctx.block_reason)
        else
            ngx.ctx.pass_reason = 'cookie'
            pcall(px_client.send_to_perimeterx, "page_requested", details)
            return true
        end
    elseif enable_server_calls == true then
        return perform_s2s(result, details)
    else
        ngx.ctx.pass_reason = 'error'
        pcall(px_client.send_to_perimeterx, "page_requested", details)
        return true
    end
end

return M
