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
	local px_constants = require("px.utils.pxconstants")
	local buffer = require "px.utils.pxbuffer"
	local px_commom_utils = require('px.utils.pxcommonutils')

	local ngx_timer_at = ngx.timer.at

	function send_initial_enforcer_telemetry()
		local details = {}
		details.px_config = px_commom_utils.filter_config(config);
		details.update_reason = 'initial_config'
		pxclient.send_enforcer_telmetry(details);
	end

	function init_remote_config()
		if config.dynamic_configurations then
			require("px.utils.config_loader").load(config_file)
		end
	end

 	function submit_on_timer()
	    local ok, err = ngx_timer_at(1, submit_on_timer)
	    if not ok then
	        px_logger.debug("Failed to schedule submit timer: " .. err)
	    end
	    local buflen = buffer.getBufferLength()
	    if buflen > 0 then
	        pcall(pxclient.submit, buffer.dumpEvents(), px_constants.ACTIVITIES_PATH)
	    end
	    return
	end
	-- Init async activities
	submit_on_timer()

	-- Enforcer telemerty first init
	local ok, err = ngx_timer_at(1, send_initial_enforcer_telemetry)
	if not ok then
		px_logger.debug("Failed to schedule telemetry on init: " .. err)
	end

	-- Init Remote configuration
	local ok, err = ngx_timer_at(1, init_remote_config)
	if not ok then
		px_logger.error("Failed to init remote config: " .. err)
	end

end
return M