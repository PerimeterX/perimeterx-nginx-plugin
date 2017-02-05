----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.4
-- Release date: 07.11.2016
----------------------------------------------

local function readonlytable(table)
    return setmetatable({}, {
        __index = table,
        __newindex = function(table, key, value)
            px_logger.error("Attempt to modify read-only constants table")
        end,
        __metatable = false
    });
end

local _M = readonlytable {
    MODULE_VERSION = "NGINX Module v2.4.0",
    RISK_PATH = "/api/v2/risk",
    CAPTCHA_PATH = "/api/v1/risk/captcha",
    ACTIVITIES_PATH = "/api/v1/collector/s2s",
}

return _M
