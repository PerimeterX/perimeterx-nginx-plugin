local _M = {}

function _M.get_configuration(config_file)
    local http = require "resty.http"
    local px_constants = require "px.utils.pxconstants"
    local config = require(config_file)
    local px_client = require("px.utils.pxclient").load(config_file)
    local px_logger = require("px.utils.pxlogger").load(config_file)
    local px_commom_utils = require("px.utils.pxcommonutils")
    local cjson = require "cjson"
    local px_conf_server = config.configuration_server
    local px_port = config.configuration_server_port
    local path = px_constants.REMOTE_CONFIGURATIONS_PATH
    local checksum = config.checksum
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
    if config.ssl_enabled == true then
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
            ["Authorization"] = "Bearer " .. config.auth_token
        },
        query = query
    })

    if err ~= nil or res == nil or res.status > 204 then
        px_logger.error("Failed to get configurations: " .. (err ~= nil and err or ''))
        if (checksum == nil) then --no configs yet and can't get configs - disable module
            px_logger.error("Disabling PX module since no configuration is available")
            config.px_enabled = false
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
        config.checksum = body.checksum
        config.px_enabled = body.moduleEnabled
        config.cookie_secret = body.cookieKey
        config.px_appId = body.appId
        config.blocking_score = body.blockingScore
        config.sensitive_headers = body.sensitiveHeaders
        config.ip_headers = body.ipHeaders
        config.px_debug = body.debugMode
        config.block_enabled = body.moduleMode ~= "monitoring"
        config.client_timeout = body.connectTimeout
        config.s2s_timeout = body.riskTimeout
        config.first_party_enabled = body.firstPartyEnabled
        config.reverse_xhr_enabled = body.firstPartyXhrEnabled
        config.report_active_config = true

        -- report enforcer telemetry
        local details = {}
        details.px_config = px_commom_utils.filter_config(config);
        details.update_reason = 'remote_config'
        px_client.send_enforcer_telmetry(details)
   end
end

function _M.load(config_file)
    local config = require(config_file)
    local ngx_timer_at = ngx.timer.at
    local px_logger = require("px.utils.pxlogger").load(config_file)
    -- set interval
    local function load_on_timer()
        local ok, err = ngx_timer_at(config.load_interval, load_on_timer)
        if not ok then
            px_logger.error("Failed to schedule submit timer: " .. err)
            if not config.config.checksum then
                px_logger.error("Disabling PX module since timer failed")
                config.px_enabled = false
            end
        else
            _M.get_configuration(config_file)
        end
        return
    end
    load_on_timer()

end

return _M
