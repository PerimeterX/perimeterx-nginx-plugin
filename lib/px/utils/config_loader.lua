local _M = {}

function _M.get_configuration(px_config)
    local http = require "resty.http"
    local px_constants = require "px.utils.pxconstants"
    
    local px_client = require("px.utils.pxclient").load(px_config)
    local px_logger = require("px.utils.pxlogger").load(px_config)
    local px_commom_utils = require("px.utils.pxcommonutils")
    local cjson = require "cjson"
    local px_conf_server = px_config.configuration_server
    local px_port = px_config.configuration_server_port
    local path = px_constants.REMOTE_CONFIGURATIONS_PATH
    local checksum = px_config.checksum
    local query
    if checksum ~= nil then
        query = '?checksum=' .. checksum
    else
        query = ''
    end

    local httpc = http.new()
    local ok, err = httpc:connect(px_conf_server, px_port)
    if not ok then
        px_logger.error("HTTPC connection error: " .. err)
    end
    if px_config.ssl_enabled == true then
        local session, err = httpc:ssl_handshake()
        if not session then
            px_logger.error("HTTPC SSL handshare error: " .. err)
        end
    end
    local res, err = httpc:request({
        path = path,
        method = "GET",
        headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. px_config.auth_token
        },
        query = query
    })

    if err ~= nil or res == nil or res.status > 204 then
        px_logger.error("Failed to get configurations: " .. (err ~= nil and err or ''))
        if (checksum == nil) then --no configs yet and can't get configs - disable module
            px_logger.error("Disabling PX module since no configuration is available")
            px_config.px_enabled = false
        end
        return
    end
    if res.status == 204 then
        px_logger.debug("Configuration was not changed")
        return
    end
    -- new configurations available
    if res.status == 200 then
        local body = res:read_body()
        px_logger.debug("Applying new configuration: " .. body)
        body = cjson.decode(body)
        px_config.checksum = body.checksum
        px_config.px_enabled = body.moduleEnabled
        px_config.cookie_secret = body.cookieKey
        px_config.px_appId = body.appId
        px_config.blocking_score = body.blockingScore
        px_config.sensitive_headers = body.sensitiveHeaders
        px_config.ip_headers = body.ipHeaders
        px_config.px_debug = body.debugMode
        px_config.block_enabled = body.moduleMode ~= "monitoring"
        px_config.client_timeout = body.connectTimeout
        px_config.s2s_timeout = body.riskTimeout
        px_config.first_party_enabled = body.firstPartyEnabled
        px_config.reverse_xhr_enabled = body.firstPartyXhrEnabled
        px_config.report_active_config = true

        -- report enforcer telemetry
        local details = {}
        details.px_config = px_commom_utils.filter_config(px_config)
        details.update_reason = 'remote_config'
        px_client.send_enforcer_telmetry(details)
   end
end

function _M.load(px_config)
    local ngx_timer_at = ngx.timer.at
    local px_logger = require("px.utils.pxlogger").load(px_config)
    -- set interval
    local function load_on_timer()
        local ok, err = ngx_timer_at(px_config.load_interval, load_on_timer)
        if not ok then
            px_logger.error("Failed to schedule submit timer: " .. err)
            if not px_config.config.checksum then
                px_logger.error("Disabling PX module since timer failed")
                px_config.px_enabled = false
            end
        else
            _M.get_configuration(px_config)
        end
        return
    end
    load_on_timer()

end

return _M
