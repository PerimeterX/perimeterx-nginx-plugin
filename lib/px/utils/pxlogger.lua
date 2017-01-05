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
            ngx_log(ngx_ERR, "PX DEBUG: " .. message)
        end
    end

    function _M.info(message)
        if (not validate_msg(message)) then
            return
        end

        ngx_log(ngx_ERR, "PX INFO: " .. message)
    end

    function _M.error(message)
        if (not validate_msg(message)) then
            return
        end

        ngx_log(ngx_ERR, "PX ERROR: " .. message)
    end
    return _M
end
return M