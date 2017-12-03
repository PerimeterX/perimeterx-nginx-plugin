---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.4
-- Release date: 07.11.2016
----------------------------------------------


local M = {}

function M.load(config_file)
    local _M = {}
    local ngx_log = ngx.log
    local ngx_ERR = ngx.ERR
    local px_config = require (config_file)

    function validate_msg(message)
        if type(message) ~= 'string' and type(message) ~= 'number'  then
            return false;
        end
        return true;
    end

    function _M.debug(message)
        if (not validate_msg(message)) then
            return
        end

        if px_config.px_debug == true then
            ngx_log(ngx_ERR, "[PerimeterX - DEBUG] [ " .. px_config.px_appId .." ] - " .. message)
        end
    end

    function _M.error(message)
        if (not validate_msg(message)) then
            return
        end

        ngx_log(ngx_ERR, "[PerimeterX - ERROR] [ " .. px_config.px_appId .." ] - " .. message)
    end

    function _M.set_score_variable(score)
		if ngx.var.pxscore then
			ngx.var.pxscore = score
		end
    end

    return _M
end
return M
