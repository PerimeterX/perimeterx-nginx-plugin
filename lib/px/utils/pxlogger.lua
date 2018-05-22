---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------

local M = {}

function M.load(px_config)
    local _M = {}
    local ngx_log = ngx.log
    local ngx_ERR = ngx.ERR

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

    function _M.enrich_log(key, value)
        if ngx.var[key] then
           ngx.var[key] = value
        end
    end

    return _M
end
return M
