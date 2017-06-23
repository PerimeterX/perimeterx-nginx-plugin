
local M = {}
function M.load()
    local _M = {}

    local socket = require("socket")

    function _M.get_time_in_milliseconds()
        return socket.gettime() * 1000
    end

    return _M
end

return M
