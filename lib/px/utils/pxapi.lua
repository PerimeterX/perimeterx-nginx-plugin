---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------
local M = {}

function M.load(px_config)
    local _M = {}

    local http = require "resty.http"
    local cjson = require "cjson"
    local px_logger = require("px.utils.pxlogger").load(px_config)
    local px_headers = require("px.utils.pxheaders").load(px_config)
    local px_constants = require "px.utils.pxconstants"
    local px_common_utils = require("px.utils.pxcommonutils")
    local sha1 = require "resty.nettle.sha1"
    local px_debug = px_config.px_debug
    local ngx_req_get_method = ngx.req.get_method
    local ngx_req_http_version = ngx.req.http_version
    local px_custom_params = {}

    -- initialize the px_custom_params table
    for i = 1, 10 do
        px_custom_params["custom_param" .. i] = ""
    end

    -- new_request_object --
    -- takes no arguments
    -- returns table
    function _M.new_request_object(call_reason)
        local risk = {}
        local cookieHeader = px_headers.get_header("cookie")
        local vid_source = "none"
        px_logger.enrich_log('pxcall', call_reason)
        risk.request = {}
        risk.request.ip = px_headers.get_ip()
        risk.request.uri = ngx.var.request_uri
        risk.request.url = ngx.var.scheme .. "://" .. ngx.var.host .. ngx.var.request_uri
        risk.request.headers = px_common_utils.filter_headers(px_config.sensitive_headers, true)
        risk.request.firstParty = px_config.first_party_enaled or false
        px_logger.debug(cjson.encode(risk.request.headers))
        risk.additional = {}
        risk.additional.s2s_call_reason = call_reason
        risk.additional.request_cookie_names = px_common_utils.extract_cookie_names(cookieHeader)
        if ngx.ctx.vid then
            risk.vid = ngx.ctx.vid
            vid_source = "risk_cookie"
        elseif ngx.ctx.pxvid then
            risk.vid = ngx.ctx.pxvid
            vid_source = "vid_cookie"
        end

        risk.additional.enforcer_vid_source = vid_source

        if ngx.ctx.pxhd then
            risk.pxhd = ngx.ctx.pxhd
        end

        if ngx.ctx.uuid then
            risk.uuid = ngx.ctx.uuid
        end

        local ssl_ciphers = ngx.var.ssl_ciphers
        if ssl_ciphers ~= nil and ssl_ciphers ~= '' then
            local ssl_ciphers_sha = ngx.encode_base64(sha1(ssl_ciphers))
            risk.additional.tls_ciphers_sha = ssl_ciphers_sha
        end

        local ssl_protocol = ngx.var.ssl_protocol
        if ssl_protocol then
            risk.additional.ssl_protocol = ssl_protocol
        end

        local ssl_cipher = ngx.var.ssl_cipher
        if ssl_cipher then
            risk.additional.ssl_cipher = ssl_cipher
        end

        local ssl_server_name = ngx.var.ssl_server_name
        if ssl_server_name then
            risk.additional.ssl_server_name = ssl_server_name
        end


        if call_reason == 'cookie_decryption_failed' then
            px_logger.debug("Attaching px_orig_cookie to request")
            risk.additional.px_orig_cookie = ngx.ctx.px_orig_cookie
        elseif call_reason == 'cookie_validation_failed' or call_reason == 'cookie_expired' then
            risk.additional.px_cookie = ngx.ctx.px_cookie
            risk.additional.px_cookie_hmac = ngx.ctx.px_cookie_hmac
        end

        if px_config.enrich_custom_parameters ~= nil then
            px_common_utils.handle_custom_parameters(px_config, px_logger, risk.additional)
        end

        risk.additional.http_version = tostring(ngx_req_http_version())
        risk.additional.http_method = ngx_req_get_method()
        risk.additional.module_version = px_constants.MODULE_VERSION
        risk.additional.cookie_origin = ngx.ctx.px_cookie_origin

        if px_config.block_enabled and not ngx.ctx.monitored_route then
            risk.additional.risk_mode = "active_blocking"
        else
            risk.additional.risk_mode = "monitor"
        end

        return risk
    end

    -- process --
    -- takes one argument - table
    -- returns boolean
    function _M.process(data)
        px_logger.debug("Processing server 2 server response: " .. cjson.encode(data.score))
        px_headers.set_score_header(data.score)
        ngx.ctx.pxhd = data.pxhd ~= nil and data.pxhd or nil

        -- Set the pxscore var for logging
        px_logger.enrich_log('pxscore',data.score)
        ngx.ctx.uuid = data.uuid or nil
        ngx.ctx.block_score = data.score
        ngx.ctx.px_action = data.action

        if data.data_enrichment then
            ngx.ctx.pxde_verified = true
            ngx.ctx.pxde = data.data_enrichment
        end

        if data.action == 'j' and data.action_data and data.action_data.body then
            ngx.ctx.px_action_data = data.action_data.body
            ngx.ctx.block_reason = "challenge"
        elseif data.action == 'r' then
            ngx.ctx.block_reason = 'exceeded_rate_limit'
        end

        if data.score >= px_config.blocking_score then
            if data.action == "c" or data.action == "b" then
                ngx.ctx.block_reason = 's2s_high_score'
            end

            px_logger.debug("Block reason - non human score: " .. data.score)
            return false
        end
        return true
    end

    -- call_s2s --
    -- takes three values, data , path, and auth_token
    -- returns response body as a table
    function _M.call_s2s(data, path, auth_token)
        local px_server = px_config.base_url
        local px_port = px_config.px_port
        local ssl_enabled = px_config.ssl_enabled
        local scheme = ssl_enabled and "https" or "http"

        data = cjson.encode(data)
        -- timeout in milliseconds
        local timeout = px_config.s2s_timeout
        -- create new HTTP connection
        local httpc = http.new()
        httpc:set_timeout(timeout)
        local ok, err = px_common_utils.call_px_server(httpc, scheme, px_server, px_port, px_config, "px_api")
        if not ok then
            px_logger.debug("HTTPC connection error: " .. err)
            error("HTTPC connection error: " .. err)
        end
        -- Perform SSL/TLS handshake
        if ssl_enabled == true then
            local session, err = httpc:ssl_handshake()
            if not session then
                px_logger.debug("HTTPC SSL handshare error: " .. err)
                error("HTTPC SSL handshare error: " .. err)
            end
        end
        -- Perform the HTTP requeset
        local res, err = httpc:request({
            path = path,
            method = "POST",
            body = data,
            headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = "Bearer " .. auth_token,
                ["Host"] = px_server
            }
        })
        if err or not res then
            px_logger.debug("Failed to make HTTP POST: " .. err)
            error("Failed to make HTTP POST: " .. err)
        elseif res.status ~= 200 then
            px_logger.debug("Non 200 response code: " .. res.status)
            error("Non 200 response code: " .. res.status)
        else
            px_logger.debug("POST response status: " .. res.status)
        end

        local body = cjson.decode(res:read_body())

        -- set keepalive to ensure connection pooling
        local ok, err = httpc:set_keepalive()
        if not ok then
            px_logger.debug("Failed to set keepalive: " .. err)
        end

        return body
    end

    return _M
end

return M
