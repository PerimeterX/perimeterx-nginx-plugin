local _M = {}

function _M.get_configuration()
    local http = require "resty.http"
    local config = require("px.pxconfig")
    local px_logger = require("px.utils.pxlogger").load("px.pxconfig")
    px_logger.debug("Fetching configuration")
    local cjson = require "cjson"
    local px_server = config.configuration_server
    local px_port = config.configuration_server_port
    local path = '/module'
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
        if (checksum == nil) then --no configs yet and can't get configs - disable module
            config.px_enabled = false
        end
    elseif res.status > 204 then
        px_logger.error("Non 20x response code: " .. res.status)
    end

    -- new configurations available
    if res.status == 200 then
        local body = cjson.decode(res:read_body())
        px_logger.debug("Applying new configuration")
        config.checksum = body.checksum
        config.px_enabled = body.moduleEnabled
        config.cookie_secret = body.cookieKey
        config.px_appId = body.appId
        config.blocking_score = body.blockingScore
        config.px_debug = body.debugMode
        config.score_header_name = body.scoreHeader
        config.block_enabled = body.moduleMode ~= "monitoring"
        config.client_timeout = body.connectTimeout
        config.s2s_timeout = body.riskTimeout
        config.block_page_template = body.blockPageTemplate
        config.captcha_page_template = body.captchaPageTemplate
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
