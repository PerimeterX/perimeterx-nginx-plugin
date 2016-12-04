---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.4
-- Release date: 07.11.2016
----------------------------------------------
local _M = {}

function _M.load(config_file)

    local http = require "resty.http"
    local px_config = require (config_file)
    local px_logger = require ("px.utils.pxlogger").load(config_file)
    local buffer = require "px.utils.pxbuffer"
    local ngx_time = ngx.time
    local tostring = tostring
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
            }
        })
        if not res then
            px_logger.error("Failed to make HTTP POST: " .. err)
            error("Failed to make HTTP POST: " .. err)
        elseif res.status ~= 200 then
            px_logger.error("Non 200 response code: " .. res.status)
            error("Non 200 response code: " .. res.status)
        else
            px_logger.debug("POST response status: " .. res.status)
        end
        -- Must read the response body to clear the buffer in order for set keepalive to work properly.
        local body = res:read_body()
        -- Check for connection reuse
        if px_debug == true then
            local times, err = httpc:get_reused_times()
            if not times then
                px_logger.debug("Error getting reuse times: " .. err)
            else
                px_logger.debug("Reused conn times: " .. times)
            end
        end
        -- set keepalive to ensure connection pooling
        local ok, err = httpc:set_keepalive()
        if not ok then
            px_logger.error("Failed to set keepalive: " .. err)
        end
    end

    function _M.send_to_perimeterx(event_type, details)
        local buflen = buffer.getBufferLength();
        local maxbuflen = px_config.px_maxbuflen;
        local full_url = ngx.var.scheme .. "://" .. ngx.var.host .. ngx.var.uri;

        if event_type == 'page_requested' and not px_config.send_page_requested_activity then
            return
        end

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
end
return _M