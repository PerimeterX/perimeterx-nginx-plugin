---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.4
-- Release date: 07.11.2016
----------------------------------------------
local M = {}

function M.load(config_file)
    local _M = {}

    local http = require "resty.http"
    local px_config = require(config_file)
    local px_logger = require("px.utils.pxlogger").load(config_file)
    local px_headers = require("px.utils.pxheaders").load(config_file)
    local buffer = require "px.utils.pxbuffer"
    local px_constants = require "px.utils.pxconstants"
    local ngx_time = ngx.time
    local tostring = tostring
    local auth_token = px_config.auth_token

    -- Submit is the function to create the HTTP connection to the PX collector and POST the data
    function _M.submit(data, path)
        local px_server = 'sapi-' .. string.lower(px_config.px_appId) .. '.perimeterx.net'
        local px_port = px_config.px_port
        local ssl_enabled = px_config.ssl_enabled
        local px_debug = px_config.px_debug
        -- timeout in milliseconds
        local timeout = px_config.client_timeout
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

        if px_config.additional_activity_handler ~= nil then
            px_logger.debug("additional_activity_handler was triggered");
            px_config.additional_activity_handler(event_type, ngx.ctx, details)
        end

        local pxdata = {};
        pxdata['type'] = event_type;
        pxdata['headers'] = ngx.req.get_headers()
        pxdata['url'] = full_url;
        pxdata['px_app_id'] = px_config.px_appId
        pxdata['timestamp'] = tostring(ngx_time())
        pxdata['socket_ip'] = px_headers.get_ip()

        details['risk_rtt'] = 0
        details['cookie_origin'] = ngx.ctx.px_cookie_origin
        if ngx.ctx.risk_rtt then
            details['risk_rtt'] = math.ceil(ngx.ctx.risk_rtt)
        end

        if ngx.ctx.vid then
            details['vid'] = ngx.ctx.vid
        end

        if ngx.ctx.uuid then
            details['client_uuid'] = ngx.ctx.uuid
        end

        if ngx.ctx.px_cookie then
            details['px_cookie'] = ngx.ctx.px_cookie
        end

        if ngx.ctx.px_cookie then
            details['px_cookie_hmac'] = ngx.ctx.px_cookie_hmac
        end

        if event_type == 'page_requested' then
            px_logger.debug("Sent page requested acitvity")
            details['pass_reason'] = ngx.ctx.pass_reason
        end

        pxdata['details'] = details;

        -- Experimental Buffer Support --
        buffer.addEvent(pxdata)
        -- Perform the HTTP action
        if buflen >= maxbuflen then
            _M.submit(buffer.dumpEvents(), px_constants.ACTIVITIES_PATH);
        end
    end


    return _M
end

return M
