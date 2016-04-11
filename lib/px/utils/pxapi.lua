---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.0
-- Release date: 21.02.2015
----------------------------------------------

local http = require "resty.http"
local cjson = require "cjson"
local px_config = require "px.pxconfig"
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local ngx_time = ngx.time
local tostring = tostring
local _M = {}

-- new_request_object --
-- takes no arguments
-- returns table
function _M.new_request_object()
    local risk = {}
    risk.cid = ''
    risk.request = {}
    risk.request.ip = ngx.var.remote_addr
    risk.request.uri = ngx.var.uri
    risk.request.headers = {}
    local h = ngx.req.get_headers()
    for k,v in pairs(h) do
        risk.request.headers[#risk.request.headers + 1] = { ['name'] = k , ['value'] = v }
    end
    return risk
end

-- process --
-- takes one argument - table
-- returns boolean
function _M.process(data)
    if data.scores.non_human >= px_config.blocking_score then
        return false
    elseif data.scores.filter >= px_config.blocking_score then
        return false
    elseif data.scores.suspected_script >= px_config.blocking_score then
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
    local px_debug = px_config.px_debug

    data = cjson.encode(data)

    -- timeout in milliseconds
    local timeout = 1000
    -- create new HTTP connection
    local httpc = http.new()
    httpc:set_timeout(timeout)
    local ok, err = httpc:connect(px_server, px_port)
    if not ok then
        ngx_log(ngx_ERR, "HTTPC connection error: ", err)
    end
    -- Perform SSL/TLS handshake
    if ssl_enabled == true then
        local session, err = httpc:ssl_handshake()
        if not session then
            ngx_log(ngx_ERR, "HTTPC SSL handshare error: ", err)
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
    if not res then
        ngx_log(ngx_ERR, "Failed to make HTTP POST: ", err)
        error("Failed to make HTTP POST: " .. err)
    elseif res.status ~= 200 then
        ngx_log(ngx_ERR, "Non 200 response code: ", res.status)
        error("Non 200 response code: " .. err)
    else
        if px_debug == true then
            ngx_log(ngx_ERR, "POST response status: ", res.status)
        end
    end

    local body = cjson.decode(res:read_body())

    -- Check for connection reuse
    if px_debug == true then
        local times, err = httpc:get_reused_times()
        if not times then
            ngx_log(ngx_ERR, "Error getting reuse times: ", err)
        end
        if px_debug == true then
            ngx_log(ngx_ERR, "Reused conn times: ", times)
        end
    end
    -- set keepalive to ensure connection pooling
    local ok, err = httpc:set_keepalive()
    if not ok then
        ngx_log(ngx_ERR, "Failed to set keepalive: ", err)
    end

    return body
end

return _M
