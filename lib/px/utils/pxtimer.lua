---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.4
-- Release date: 07.11.2016
----------------------------------------------
local M = {}

function M.application(file_name)
	local config_file = ((file_name == nil or file_name == '') and "px.pxconfig" or "px.pxconfig-" .. file_name)

	local config = require (config_file)
	local pxclient = require ("px.utils.pxclient").load(config_file)
	local px_logger = require ("px.utils.pxlogger").load(config_file)
	local buffer = require "px.utils.pxbuffer"

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
end
return M