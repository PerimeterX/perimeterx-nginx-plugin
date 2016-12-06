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
    MODULE_VERSION = "NGINX Module v2.0.0"
}

return _M
