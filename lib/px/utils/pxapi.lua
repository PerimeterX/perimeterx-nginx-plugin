---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.0
-- Release date: 21.02.2015
----------------------------------------------

local http = require "resty.http"
local cjson = require "cjson"
local px_config = require "px.pxconfig"
local px_logger = require "px.utils.pxlogger"
local px_headers = require "px.utils.pxheaders"
local px_debug = px_config.px_debug

local _M = {}

-- new_request_object --
-- takes no arguments
-- returns table
function _M.new_request_object(call_reason)
    local risk = {}
    risk.cid = ''
    risk.request = {}
    risk.request.ip = ngx.var.remote_addr
    risk.request.uri = ngx.var.uri
    risk.request.headers = {}
    local h = ngx.req.get_headers()
    for k, v in pairs(h) do
        risk.request.headers[#risk.request.headers + 1] = { ['name'] = k, ['value'] = v }
    end
    risk.additional = {}
    risk.additional.s2s_call_reason = call_reason

    if call_reason == 'cookie_validation_failed' or call_reason == 'cookie_expired' then
        risk.additional.px_cookie = ngx.ctx.px_cookie
        local dec_cookie = cjson.decode(ngx.ctx.px_cookie);
        risk.vid = dec_cookie.v
        risk.uuid = dec_cookie.u
    end

    risk.additional.http_version = ngx.req.http_version()
    risk.additional.http_method = ngx.req.get_method()

    risk.additional.module_version = 'NGINX Module v1.1.2'

    return risk
end

-- process --
-- takes one argument - table
-- returns boolean
function _M.process(data)
    px_logger.debug("Processing server 2 server response: " .. cjson.encode(data.scores))
    px_headers.set_score_header(data.scores.non_human)
    if data.scores.non_human >= px_config.blocking_score then
        ngx.ctx.uuid = data.uuid
        ngx.ctx.block_score = data.scores.non_human
        px_logger.error("Block reason - non human score: " .. data.scores.non_human)
        return false
    end
    return true
end

-- call_s2s --
-- takes three values, data , path, and auth_token
-- returns response body as a table
function _M.call_s2s(data, path, auth_token)
    local px_server = px_config.px_server
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
        px_logger.error("HTTPC connection error: " .. err)
    end
    -- Perform SSL/TLS handshake
    if ssl_enabled == true then
        local session, err = httpc:ssl_handshake()
        if not session then
            px_logger.error("HTTPC SSL handshare error: " .. err)
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
        px_logger.error("Failed to make HTTP POST: " .. err)
        error("Failed to make HTTP POST: " .. err)
    elseif res.status ~= 200 then
        px_logger.error("Non 200 response code: " .. res.status)
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
        px_logger.error("Failed to set keepalive: " .. err)
    end

    return body
end

return _M
