---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------

local M = {}

function M.application(px_configutraion_table)
	local config_builder = require("px.utils.config_builder");

	local px_config = config_builder.load(px_configutraion_table)

	local pxclient = require ("px.utils.pxclient").load(px_config)
	local px_logger = require ("px.utils.pxlogger").load(px_config)
	local px_constants = require("px.utils.pxconstants")
	local buffer = require "px.utils.pxbuffer"

	local ngx_timer_at = ngx.timer.at

	function init_remote_config()
		if px_config == nil or not px_config.px_enabled then
			px_logger.debug("module is disabled, skipping remote config")
			return
		end

		if px_config.px_appId == 'PX_APP_ID' then
			return
		end

		if px_config.dynamic_configurations then
			require("px.utils.config_loader").load(px_config)
		end
	end

	function submit_on_timer()
		if px_config == nil or not px_config.px_enabled then
			px_logger.debug("module is disabled, skipping submit timer")
			return
		end

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

	-- Init Remote configuration
	local ok, err = ngx_timer_at(1, init_remote_config)
	if not ok then
		px_logger.error("Failed to init remote config: " .. err)
	end

end
return M
