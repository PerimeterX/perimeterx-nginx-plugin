---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------
local M = {}

function M.load(config_file)
    local _M = {}

    local http = require "resty.http"
    local cjson = require "cjson"
    local px_config = require(config_file)
    local px_logger = require("px.utils.pxlogger").load(config_file)
    local px_headers = require("px.utils.pxheaders").load(config_file)
    local px_constants = require "px.utils.pxconstants"
    local px_common_utils = require("px.utils.pxcommonutils")
    local px_debug = px_config.px_debug
    local ngx_req_get_method = ngx.req.get_method
    local ngx_req_http_version = ngx.req.http_version
    -- new_request_object --
    -- takes no arguments
    -- returns table
    function _M.new_request_object(call_reason)
        local risk = {}
        px_logger.enrich_log('pxcall', call_reason)
        risk.cid = ''
        risk.request = {}
        risk.request.ip = px_headers.get_ip()
        risk.request.uri = ngx.var.request_uri
        risk.request.headers = px_common_utils.filter_headers(px_config.sensitive_headers, true)
        risk.request.firstParty = px_config.first_party_enaled or false
        
        px_logger.debug(cjson.encode(risk.request.headers))
        risk.additional = {}
        risk.additional.s2s_call_reason = call_reason
        
        if ngx.ctx.vid then
            risk.vid = ngx.ctx.vid
        end

        if ngx.ctx.uuid then
            risk.uuid = ngx.ctx.uuid
        end

        if call_reason == 'cookie_decryption_failed' then
            px_logger.debug("Attaching px_orig_cookie to request")
            risk.additional.px_orig_cookie = ngx.ctx.px_orig_cookie
        elseif call_reason == 'cookie_validation_failed' or call_reason == 'cookie_expired' then
            risk.additional.px_cookie = ngx.ctx.px_cookie
            risk.additional.px_cookie_hmac = ngx.ctx.px_cookie_hmac
        end

        risk.additional.http_version = ngx_req_http_version()
        risk.additional.http_method = ngx_req_get_method()
        risk.additional.module_version = px_constants.MODULE_VERSION
        risk.additional.cookie_origin = ngx.ctx.px_cookie_origin

        return risk
    end

    -- process --
    -- takes one argument - table
    -- returns boolean
    function _M.process(data)
        px_logger.debug("Processing server 2 server response: " .. cjson.encode(data.score))

        px_headers.set_score_header(data.score)
        -- Set the pxscore var for logging
        px_logger.enrich_log('pxscore',data.score)

        ngx.ctx.uuid = data.uuid or nil
        ngx.ctx.block_score = data.score
        ngx.ctx.px_action = data.action

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

        data = cjson.encode(data)
        -- timeout in milliseconds
        local timeout = px_config.s2s_timeout
        -- create new HTTP connection
        local httpc = http.new()
        httpc:set_timeout(timeout)
        local ok, err = httpc:connect(px_server, px_port)
        if not ok then
            px_logger.debug("HTTPC connection error: " .. err)
            error('HTTPC connection error:'  .. err)
        end
        -- Perform SSL/TLS handshake
        if ssl_enabled == true then
            local session, err = httpc:ssl_handshake()
            if not session then
                px_logger.debug("HTTPC SSL handshare error: " .. err)
            end
        end
        -- Perform the HTTP requeset
        local res, err = httpc:request({
            path = path,
            method = "POST",
            body = data,
            headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = "Bearer " .. auth_token
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

        -- Check for connection reuse
        if px_debug == true then
            local times, err = httpc:get_reused_times()
            if not times then
                px_logger.debug("Error getting reuse times: " .. err)
            end
        end
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
