local socket = require("socket")
local _M = {}

function _M.get_time_in_milliseconds()
    return socket.gettime() * 1000
end

function _M.array_index_of(array, item)
    if array == nil then
        return -1
    end

    for i, value in ipairs(array) do
        if value == item then
            return i
        end
    end
    return -1
end

function clone (t) -- deep-copy a table
    if type(t) ~= "table" then return t end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            target[k] = clone(v)
        else
            target[k] = v
        end
    end
    setmetatable(target, meta)
    return target
end

function  _M.filter_config(px_config)
    local config_copy = clone(px_config);
    -- remove
    config_copy.cookie_secret = nil
    config_copy.auth_token = nil
    return config_copy
end

return _M
