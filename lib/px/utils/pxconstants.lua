----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.2
-- Release date: 05.04.2016
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
    MODULE_VERSION = "NGINX Module v1.1.2"
}

return _M
