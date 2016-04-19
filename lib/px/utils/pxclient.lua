---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.0
-- Release date: 21.02.2015
----------------------------------------------

local http = require "resty.http"
local buffer = require "px.utils.pxbuffer"
local px_config = require "px.pxconfig"
local ngx_log = ngx.log
local ngx_time = ngx.time
local tostring = tostring
local ngx_ERR = ngx.ERR
local _M = {}

-- Submit is the function to create the HTTP connection to the PX collector and POST the data
function _M.submit(data, path)
    local px_server = px_config.px_server
    local px_port = px_config.px_port
    local ssl_enabled = px_config.ssl_enabled
    local px_debug = px_config.px_debug
    -- timeout in milliseconds
    local timeout = 2000
    -- create new HTTP connection
    local httpc = http.new()
    httpc:set_timeout(timeout)
    local ok, err = httpc:connect(px_server, px_port)
    if not ok then
        ngx_log(ngx_ERR, "PX ERROR: HTTPC connection error: ", err)
    end
    -- Perform SSL/TLS handshake
    if ssl_enabled == true then
        local session, err = httpc:ssl_handshake()
        if not session then
            ngx_log(ngx_ERR, "PX ERROR: HTTPC SSL handshare error: ", err)
        end
    end
    -- Perform the HTTP requeset
    local res, err = httpc:request({
        path = path,
        method = "POST",
        body = data,
        headers = {
            ["Content-Type"] = "application/json",
        }
    })
    if not res then
        ngx_log(ngx_ERR, "PX ERROR: Failed to make HTTP POST: ", err)
        error("Failed to make HTTP POST: " .. err)
    elseif res.status ~= 200 then
        ngx_log(ngx_ERR, "PX ERROR: Non 200 response code: ", res.status)
        error("Non 200 response code: " .. err)
    else
        if px_debug == true then
            ngx_log(ngx_ERR, "PX DEBUG: POST response status: ", res.status)
        end
    end
    -- Must read the response body to clear the buffer in order for set keepalive to work properly.
    local body = res:read_body()
    -- Check for connection reuse
    if px_debug == true then
        local times, err = httpc:get_reused_times()
        if not times then
            ngx_log(ngx_ERR, "PX ERROR: Error getting reuse times: ", err)
        end
            ngx_log(ngx_ERR, "PX DEBUG: Reused conn times: ", times)
    end
    -- set keepalive to ensure connection pooling
    local ok, err = httpc:set_keepalive()
    if not ok then
        ngx_log(ngx_ERR, "PX ERROR: Failed to set keepalive: ", err)
    end
end

function _M.send_to_perimeterx(event_type, details)
    local buflen = buffer.getBufferLength();
    local maxbuflen = px_config.px_maxbuflen;
    local full_url = ngx.var.scheme .. "://" .. ngx.var.host .. ngx.var.uri;

    local pxdata = {};
    pxdata['type'] = event_type;
    pxdata['headers'] = ngx.req.get_headers()
    pxdata['url'] = full_url;
    pxdata['px_app_id'] = px_config.px_appId;
    pxdata['timestamp'] = tostring(ngx_time());
    pxdata['socket_ip'] = ngx.var.remote_addr;
    pxdata['details'] = details;

    -- Experimental Buffer Support --
    buffer.addEvent(pxdata)
    -- Perform the HTTP action
    if buflen >= maxbuflen then
        _M.submit(buffer.dumpEvents(), px_config.nginx_collector_path);
    end
end


return _M
