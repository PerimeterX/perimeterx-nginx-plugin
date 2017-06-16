--
-- Created by IntelliJ IDEA.
-- User: nitzangoldfeder
-- Date: 16/06/2017
-- Time: 12:17
-- To change this template use File | Settings | File Templates.
--
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