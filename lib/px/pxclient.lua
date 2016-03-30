---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.0
-- Release date: 21.02.2015
----------------------------------------------

local http = require "resty.http"
local buffer = require "px.pxbuffer"
local config = require "px.pxconfig"
local ngx_log = ngx.log
local ngx_time = ngx.time
local tostring = tostring
local ngx_ERR = ngx.ERR
local CLIENT = {}

-- Submit is the function to create the HTTP connection to the PX collector and POST the data
function CLIENT.submit(data)
    local px_server = config.px_server
    local px_port = config.px_port
    local ssl_enabled = config.ssl_enabled
    local px_debug = config.px_debug
    -- timeout in milliseconds
    local timeout = 2000
    -- create new HTTP connection
    local httpc = http.new()
    httpc:set_timeout(timeout)
    local ok, err =  httpc:connect(px_server,px_port)
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
        path = '/api/v1/collector/nginxcollect',
        method = "POST",
        body = data,
        headers = {
            ["Content-Type"] = "application/json",
        }
    })
    if not res then
        ngx_log(ngx_ERR, "Failed to make HTTP POST: ",err)
        return
    elseif res.status ~= 200 then
        ngx_log(ngx_ERR, "Non 200 response code: ", res.status)
        return
    else
        if px_debug == true then
            ngx_log(ngx_ERR, "POST response status: ", res.status)
        end
    end
    -- Must read the response body to clear the buffer in order for set keepalive to work properly.
    local body = res:read_body()
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
end

function CLIENT.sendTo_Perimeter(event_type)
    local buflen = buffer.getBufferLength()
    local maxbuflen = config.px_maxbuflen
    local pxdata = {}
    pxdata['method'] = ngx.ctx.method
    pxdata['type'] = event_type;
    pxdata['headers'] = ngx.ctx.headers
    pxdata['px_app_id'] = config.px_appId
    pxdata['px_token'] = config.px_token
    pxdata['pxidentifier'] = ngx.ctx.pxidentifier
    pxdata['host'] = ngx.ctx.host
    pxdata['timestamp'] = tostring(ngx_time())
    pxdata['uri'] = ngx.ctx.uri
    pxdata['user-agent'] = ngx.ctx.user_agent
    pxdata['socket_ip'] = ngx.ctx.remote_addr;

    -- Experimental Buffer Support --
    buffer.addEvent(pxdata)
    -- Perform the HTTP action
    if buflen >= maxbuflen then
        CLIENT.submit(buffer.dumpEvents())
    end
end

return CLIENT
