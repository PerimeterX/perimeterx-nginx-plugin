----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.5.0
-- Release date: 05.04.2016
----------------------------------------------

local config = require "px.pxconfig"
local buffer = require "px.utils.pxbuffer"
local pxclient = require "px.utils.pxclient"
local px_logger = require "px.utils.pxlogger"

local ngx_timer_at = ngx.timer.at

local function submit_on_timer()
    local ok, err = ngx_timer_at(1, submit_on_timer)
    if not ok then
        px_logger.error("Failed to schedule submit timer: " .. err)
    end
    local buflen = buffer.getBufferLength()
    if buflen > 0 then
        pxclient.submit(buffer.dumpEvents(), config.nginx_collector_path)
    end
    return
end

submit_on_timer()
