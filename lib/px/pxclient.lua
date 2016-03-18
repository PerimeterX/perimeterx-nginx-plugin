---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.0
-- Release date: 21.02.2015
----------------------------------------------

local cjson = require "cjson"
local http = require "resty.http"
local buffer = require "px.pxbuffer"
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local CLIENT = {}

function CLIENT.sendTo_Perimeter(event_type)
    local pxdata = {}
    pxdata['method'] = ngx.ctx.method
    pxdata['type'] = event_type;
    pxdata['headers'] = ngx.ctx.headers
    pxdata['px_app_id'] = ngx.ctx.px_app_id
    pxdata['pxtoken'] = ngx.ctx.pxtoken
    pxdata['pxidentifier'] = ngx.ctx.pxidentifier
    pxdata['host'] = ngx.ctx.host
    pxdata['timestamp'] = tostring(ngx.time())
    pxdata['uri'] = ngx.ctx.uri
    pxdata['user-agent'] = ngx.ctx.user_agent
    pxdata['socket_ip'] = ngx.ctx.remote_addr;

    -- Experimental Buffer Support --
    buffer.addEvent(pxdata)
    local buflen = buffer.getBufferLength()

    local pxserver = ngx.ctx.pxserver
    local pxport = ngx.ctx.pxport
    local sslEnabled = ngx.ctx.sslEnabled

    -- Submit is the function to create the HTTP connection to the PX collector and POST the data
    local submit = function(data)
        local pxdebug = ngx.ctx.pxdebug
        -- timeout in milliseconds
        local timeout = 2000
        -- create new HTTP connection
        local httpc = http.new()
        httpc:set_timeout(timeout)
        local ok, err =  httpc:connect(pxserver,pxport)
        if not ok then
            ngx_log(ngx_ERR, "HTTPC connection error: ", err)
        end
        -- Perform SSL/TLS handshake
        if sslEnabled == true then
            local session, err = httpc:ssl_handshake()
            if not session then
                ngx_log(ngx_ERR, "HTTPC SSL handshare error: ", err)
            end
        end
        -- Perform the HTTP requeset
        local res, err = httpc:request({
            path = '/api/v1/collector/nginxcollect',
            method = "POST",
            body = "data=" .. data,
            headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded",
            }
        })
        if not res then
            ngx_log(ngx_ERR, "Failed to make HTTP POST: ",err)
            return
        elseif res.status ~= 200 then
            ngx_log(ngx_ERR, "Non 200 response code: ", res.status)
            return
        else
            if pxdebug == true then
                ngx_log(ngx_ERR, "POST response status: ", res.status)
            end
        end
        -- Must read the response body to clear the buffer in order for set keepalive to work properly.
        local body = res:read_body()
        -- Check for connection reuse
        if pxdebug == true then
            local times, err = httpc:get_reused_times()
            if not times then
                ngx_log(ngx_ERR, "Error getting reuse times: ", err)
            end
            if pxdebug == true then
                ngx_log(ngx_ERR, "Reused conn times: ", times)
            end
        end
        -- set keepalive to ensure connection pooling
        local ok, err = httpc:set_keepalive()
        if not ok then
            ngx_log(ngx_ERR, "Failed to set keepalive: ", err)
        end
    end
    -- Perform the HTTP action
    if buflen >= 500 then
        submit(buffer.dumpEvents())
    end
end

return CLIENT
