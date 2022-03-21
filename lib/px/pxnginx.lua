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
    local config_builder = require("px.utils.config_builder")

    local px_config = config_builder.load(px_configuration_table)
    local _M = {}
    -- Support for multiple apps - each app file should be named "pxconfig-<appname>.lua"
    local px_filters = require("px.utils.pxfilters").load(px_config)
    local px_client = require("px.utils.pxclient").load(px_config)
    local PXPayload = require('px.utils.pxpayload')
    local px_payload = PXPayload:new {}
    local px_block = require("px.block.pxblock").load(px_config)
    local px_api = require("px.utils.pxapi").load(px_config)
    local px_logger = require("px.utils.pxlogger").load(px_config)
    local px_headers = require("px.utils.pxheaders").load(px_config)
    local px_data_enrichment = require("px.utils.pxdataenrichment").load(px_config)
    local px_constants = require("px.utils.pxconstants")
    local px_common_utils = require("px.utils.pxcommonutils")
    local px_telemetry = require("px.utils.pxtelemetry")
    local px_creds = require ("px.utils.pxlogin_credentials").load(px_config)
    local px_graphql = require ("px.utils.pxgraphql_extractor").load(px_config)
    local cjson = require "cjson"

    local auth_token = px_config.auth_token
    local enable_server_calls = px_config.enable_server_calls
    local risk_api_path = px_constants.RISK_PATH
    local enabled_routes = px_config.enabled_routes
    local monitored_routes = px_config.monitored_routes
    local pxhd_secure_enabled = px_config.pxhd_secure_enabled
    local remote_addr = px_headers.get_ip()
    local user_agent = ngx.var.http_user_agent or ""
    local string_sub = string.sub
    local string_len = string.len
    local pcall = pcall

    local reverse_prefix_appid = string.sub(px_config.px_appId, 3, string.len(px_config.px_appId))
    local reverse_prefix = px_config.first_party_prefix ~= nil and px_config.first_party_prefix .. '/' .. reverse_prefix_appid or reverse_prefix_appid
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

    local function shouldServeHsc()
        if ngx.ctx.isHypeSale then
            return true
        else
            return false
        end
    end

    local function shouldServeHscOnDrc()
        if ngx.ctx.drc and ngx.ctx.drc == px_constants.HSC_DRC_PROPERTY and ngx.ctx.isHypeSale then
            return true
        else
            return false
        end
    end

    local function perform_s2s(result, details, creds, graphql, custom_params)
        px_logger.debug("Evaluating Risk API request, call reason: " .. result.message)
        ngx.ctx.s2s_call_reason = result.message
        local cookie_expires = 31536000 -- one year
        local request_data = px_api.new_request_object(result.message, details, custom_params)
        local start_risk_rtt = px_common_utils.get_time_in_milliseconds()
        local success, response = pcall(px_api.call_s2s, request_data, risk_api_path, auth_token)
        local cookie_secure_directive = ""

        ngx.ctx.risk_rtt = px_common_utils.get_time_in_milliseconds() - start_risk_rtt
        ngx.ctx.is_made_s2s_api_call = true

        local result
        if success then
            result = px_api.process(response)
            px_logger.debug("Risk API response returned successfully, risk score: " .. ngx.ctx.block_score .. ", round_trip_time: " .. ngx.ctx.risk_rtt)

            if shouldServeHscOnDrc() then
                px_logger.debug("Serving HSC page")
                ngx.header["Set-Cookie"] = "_pxhd=''; Path=/"
                ngx.ctx.px_action = px_constants.HSC_BLOCK_ACTION
                ngx.ctx.pass_reason = 'checkpoint_page'
                pcall(px_client.send_to_perimeterx, "page_requested", details)
                px_block.serve_hsc(ngx.ctx.block_reason)
                return true
            end

            -- handle pxhd cookie
            if ngx.ctx.pxhd ~= nil then
                ngx.header["Content-Type"] = nil

                if (pxhd_secure_enabled == true) then
                    cookie_secure_directive = "; Secure"
                end

                ngx.header["Set-Cookie"] = "_pxhd=" .. ngx.ctx.pxhd ..  cookie_secure_directive  .. "; Expires=" .. ngx.cookie_time(ngx.time() + cookie_expires) .. "; Path=/"
            end

            -- set compromised credentials header
            if px_config.px_enable_login_creds_extraction and ngx.ctx.breached_account and px_config.px_compromised_credentials_header_name then
                px_logger.debug("Setting compromised credentials header '"..
                    px_config.px_compromised_credentials_header_name.."' to '"..tostring(ngx.ctx.breached_account).."'")
                if ngx.ctx.breached_account then
                    ngx.req.set_header(px_config.px_compromised_credentials_header_name, "1")
                else
                    ngx.req.set_header(px_config.px_compromised_credentials_header_name, "0")
                end
            end

            -- case score crossed threshold
            if not result then
                px_logger.debug("Request will be blocked due to: " .. ngx.ctx.block_reason)
                return px_block.block(ngx.ctx.block_reason, creds, graphql)
            end
            -- score did not cross the blocking threshold
            ngx.ctx.pass_reason = 's2s'
            pcall(px_client.send_to_perimeterx, "page_requested", details, creds)
            return true
        else
            -- server2server call failed, passing traffic
            ngx.ctx.pass_reason = 'error'
            if string.match(response, 'timeout') then
                px_logger.debug('Risk API timed out - rtt: ' .. ngx.ctx.risk_rtt)
                ngx.ctx.pass_reason = 's2s_timeout'
            end
            px_logger.debug('Risk API failed with error: ' .. response)
            px_client.send_to_perimeterx("page_requested", details, creds)
            return true
        end
    end


    math.randomseed(px_common_utils.get_time_in_milliseconds())
    ngx.ctx.client_uuid = px_common_utils.generate_uuid()

    -- by default it's set as finalized, no need to call page_requested
    local px_data = {}
    ngx.ctx.px_data = px_data
    px_data["px_config"] = px_config
    px_data["px_creds"] = px_creds

    -- check for x-px-enforcer-telemetry header
    local ran, error_msg = pcall(px_telemetry.telemetry_check_header, px_config, px_client, px_headers, px_logger)
    if not ran then
        px_logger.debug("telemetry_check_header encountered an error: " .. error_msg)
    end

    -- Match for client/XHRs/captcha
    if is_first_party_request(reverse_prefix, lower_request_url) then
        return px_data
    end

    if not px_config.px_enabled then
        px_logger.debug("Request will not be verified, module is disabled")
        return px_data
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
        return px_data
    end

     -- Check for monitored route
    for i = 1, #monitored_routes do
        if string_sub(ngx.var.uri, 1, string_len(monitored_routes[i])) == monitored_routes[i] then
            px_logger.debug("Found monitored route prefix: " .. monitored_routes[i])
            ngx.ctx.monitored_route = true
        end
    end

    -- Validate if request is from internal redirect to avoid duplicate processing
    if px_headers.validate_internal_request() then
        return px_data
    end

    -- Clean any protected headers from the request.
    -- Prevents header spoofing to upstream application
    px_headers.clear_protected_headers()

    -- run filter and whitelisting logic
    if (px_filters.process()) then
        px_headers.set_score_header(0)
        return px_data
    end

    px_logger.debug("Starting request verification. IP: " .. remote_addr .. ". UA: " .. user_agent .. ". Client UUID: " .. ngx.ctx.client_uuid)

    local details = {}

    -- handle pxde cookie
    local pxde = ngx.var.cookie__pxde
    if pxde then
        local success, result = pcall(px_data_enrichment.process, pxde)
        if not success then
            px_logger.debug("Failed to process pxde")
        end
    end

    -- handle pxhd cookie
    local pxhd = ngx.var.cookie__pxhd
    if pxhd then
        ngx.ctx.pxhd = pxhd
    end

    -- handle pxvid cookie and validation
    local x = "%x"
    local t = { x:rep(8), x:rep(4), x:rep(4), x:rep(4), x:rep(12) }
    local pattern = table.concat(t, '%-')
    local pxvid = ""

    if ngx.var.cookie__pxvid ~= nil and ngx.var.cookie__pxvid ~= "" and ngx.var.cookie__pxvid:match(pattern) then
        pxvid = ngx.var.cookie__pxvid
    elseif ngx.var.cookie_pxvid ~= nil and ngx.var.cookie_pxvid ~= "" and ngx.var.cookie_pxvid:match(pattern) then
        pxvid = ngx.var.cookie_pxvid
    end
    if pxvid ~= "" then
        ngx.ctx.pxvid = pxvid
    end

    local graphql = px_graphql.extract(lower_request_url)
    if graphql then
        details["graphql_operation_name"] = graphql["operationName"]
        details["graphql_operation_type"] = graphql["operationType"]
    end

    local creds = px_creds.px_credentials_extract()
    if creds then
        details["user"] = creds["user"]
        details["pass"] = creds["pass"]
        details["ci_version"] = creds["ci_version"]
        details["sso_step"] = creds["sso_step"]

        ngx.ctx.ci_version = details["ci_version"]
        ngx.ctx.sso_step = details["sso_step"]
        ngx.ctx.ci_raw_user = creds["raw_user"]
    end

    px_payload:load(px_config)
    local px_cookie = px_payload:get_payload()
    local success = false
    local result
    if px_cookie ~= nil then
        px_cookie:load(px_config)
        success, result = pcall(px_cookie.process, px_cookie)
    else
        local no_cookie_message = "no_cookie"
        if ngx.ctx.pxhd then
            no_cookie_message = "no_cookie_w_vid"
        end
        result = { message = no_cookie_message }
    end

    if px_config.px_enable_login_creds_extraction and
        px_config.px_additional_s2s_activity_header_enabled and
        px_creds.creds_has_uri_path() then

        px_logger.debug("Attaching additional_activity_header")
        local buf = px_creds.create_additional_s2s(false, true)

        if buf then
            buf = cjson.encode(buf)
            ngx.req.set_header(px_constants.ADDITIONAL_ACTIVITY_HEADER,  buf)
            local scheme = px_config.ssl_enabled and "https" or "http"
            ngx.req.set_header(px_constants.ADDITIONAL_ACTIVITY_URL_HEADER,  scheme .. "://" .. px_config.base_url .. px_constants.ACTIVITIES_PATH)
        end
    end

    local custom_params = px_common_utils.handle_custom_parameters(px_config, px_logger)

    if shouldServeHsc() then
        px_logger.debug("is HSC route")

        local call_reason = nil
        if result and type(result) == 'table' then
            call_reason = result.message
        end

        if (success or call_reason == "sensitive_route") and ngx.ctx.hscApproval then
            px_logger.debug("HSC page: Cookie is verified and the HSC Approval value is true - HSC Passed!")
            result = { message = "hsc_route" }
            success = false
        else
            px_logger.debug("Serving HSC page")
            ngx.header["Set-Cookie"] = "_pxhd=''; Path=/"
            ngx.ctx.px_action = px_constants.HSC_BLOCK_ACTION
            ngx.ctx.pass_reason = 'checkpoint_page'
            pcall(px_client.send_to_perimeterx, "page_requested", details)
            px_block.serve_hsc(ngx.ctx.block_reason)
            return px_data
        end
    end

    -- cookie verification passed - checking result.
    if success then
        px_logger.debug("Cookie evaluation ended successfully, risk score: " .. ngx.ctx.block_score)
        details["px_cookie"] = ngx.ctx.px_cookie
        details["px_cookie_hmac"] = ngx.ctx.px_cookie_hmac
        details["px_cookie_version"] = ngx.ctx.px_cookie_version

        px_logger.enrich_log('pxscore', ngx.ctx.block_score)
        px_logger.enrich_log('pxcookiets', ngx.ctx.cookie_timestamp)
        -- score crossed threshold
        if result == false then
            ngx.ctx.block_reason = 'cookie_high_score'
            px_block.block(ngx.ctx.block_reason, creds, graphql)
            return px_data
        else
            ngx.ctx.pass_reason = 'cookie'
            pcall(px_client.send_to_perimeterx, "page_requested", details, creds)
        end
    elseif enable_server_calls == true then
        if result == nil then
            result = { message = "cookie_error" }
        end
        perform_s2s(result, details, creds, graphql, custom_params)
    else
        ngx.ctx.pass_reason = 'error'
        pcall(px_client.send_to_perimeterx, "page_requested", details, creds)
    end

    px_data["details"] = details

    return px_data
end

-- must be called from header_filter_by_lua_block{}
function M.finalize()
    if not ngx.ctx.px_data then
        return
    end

    -- do not send additional_s2s if blocked
    if ngx.ctx.block_reason then
        return
    end

    local px_config = ngx.ctx.px_data["px_config"]
    local px_creds = ngx.ctx.px_data["px_creds"]
    local px_client = require("px.utils.pxclient").load(px_config)
    local px_logger = require("px.utils.pxlogger").load(px_config)

    if px_config.px_enable_login_creds_extraction and
        not px_config.px_additional_s2s_activity_header_enabled and
        px_creds.creds_has_uri_path() then

        local is_login_successful = px_creds.creds_is_login_successful()

        px_logger.debug("Sending additional_s2s activity")
        pcall(px_client.send_additional_s2s, is_login_successful)
    end
end

return M
