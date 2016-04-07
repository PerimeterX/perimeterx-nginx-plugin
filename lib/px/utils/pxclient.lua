---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.0
-- Release date: 21.02.2015
----------------------------------------------

local http = require "resty.http"
local buffer = require "px.utils.pxbuffer"
local config = require "px.pxconfig"
local cjson = require "cjson"
local ngx_log = ngx.log
local ngx_time = ngx.time
local tostring = tostring
local ngx_ERR = ngx.ERR
local CLIENT = {}

-- Submit is the function to create the HTTP connection to the PX collector and POST the data
function CLIENT.submit(data, path, additional_headers)
    local px_server = config.px_server
    local px_port = config.px_port
    local ssl_enabled = config.ssl_enabled
    local px_debug = config.px_debug
    -- timeout in milliseconds
    local timeout = 2000
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

    -- Extending headers
    local headers = {
        ["Content-Type"] = "application/json",
    }
    if (additional_headers) then
        for k,v in pairs(additional_headers) do headers[k] = v end
    end

    -- Perform the HTTP requeset
    local res, err = httpc:request({
        path = path,
        method = "POST",
        body = data,
    })
    if not res then
        ngx_log(ngx_ERR, "Failed to make HTTP POST: ", err)
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
        return false
    end

    return body
end

function CLIENT.sendActivityTo_Perimeter(event_type)
    local buflen = buffer.getBufferLength()
    local maxbuflen = config.px_maxbuflen
    local pxdata = {}

    pxdata['type'] = event_type;
    pxdata['headers'] = ngx.req.get_headers();
    pxdata['px_app_id'] = config.px_appId;
    pxdata['timestamp'] = tostring(ngx_time());
    pxdata['socket_ip'] = ngx.var.remote_addr;

    -- Experimental Buffer Support --
    buffer.addEvent(pxdata)
    -- Perform the HTTP action
    if buflen >= maxbuflen then
        CLIENT.submit(buffer.dumpEvents(), config.nginx_collect_path);
    end
end

function CLIENT.retriveScoreFromServer()
    local pxdata = {}
    pxdata['request'] = {};
    pxdata['request']['ip'] = ngx.var.remote_addr;
    pxdata['request']['uri'] = ngx.var.uri;
    pxdata['request']['headers'] = ngx.req.get_headers();
    local body = cjson.encode(pxdata)

    local headers = {
        ['Authorization'] = "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzY29wZXMiOlsicmlza19zY29yZSIsInJlc3RfYXBpIl0sImlhdCI6MTQ1ODYzODE2NCwic3ViIjoiUFg2MDAyIiwianRpIjoiZGEzY2U1ZGMtNjY2Mi00ZGRlLThhYTYtMWFhNzI4MTIzMzMzIn0.Rrz5MUKceV7wyxqnEyJ-MKq1QA4SpVJ6-aAMNem4tn0"
    }

    return CLIENT.submit(body, config.risk_score_api_path, headers);
end

return CLIENT