local _M = {}

function _M.get_configuration()
    local http = require "resty.http"
    local config = require("px.pxconfig")
    local px_logger = require("px.utils.pxlogger").load("px.pxconfig")
    px_logger.debug("Fetching configuration")
    local cjson = require "cjson"
    local px_server = '10.20.1.148'
    local px_port = 8080
    local path = '/module/'
    local checksum = config.checksum
    local query
    if checksum ~= nil then
        query = '?checksum=' .. checksum
    else
        query = ''
    end
    local httpc = http.new()
    local ok, err = httpc:connect(px_server, px_port)
    if not ok then
        px_logger.error("HTTPC connection error: " .. err)
    end
    local res, err = httpc:request({
        path = path,
        method = "GET",
        headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. config.auth_token
        },
        query = query
    })
    if err or not res then
        px_logger.error("Failed to make HTTP POST: " .. err)
    elseif res.status ~= 200 then
        px_logger.error("Non 200 response code: " .. res.status)
    end
    local body = cjson.decode(res:read_body())
    -- new configurations available
    if body.appId ~= nil then
        config.checksum = body.checksum
        config.cookie_secret = body.cookieKey
        config.px_appId = body.appId
        config.blocking_score = body.blockingScore
   end
end

function _M.load()

    local ngx_timer_at = ngx.timer.at
    -- set interval
    local function load_on_timer()
        local ok, err = ngx_timer_at(60, load_on_timer)
        if not ok then
            px_logger.error("Failed to schedule submit timer: " .. err)
        end
        _M.get_configuration()
        return
    end
    load_on_timer()

end

return _M
