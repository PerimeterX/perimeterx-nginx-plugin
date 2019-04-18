local hmac = require "resty.nettle.hmac"
local px_commom_utils = require('px.utils.pxcommonutils')

local M = {}

function M.telemetry_check_header(px_config, px_client)
    local header_value = px_headers.get_header(px_constants.ENFORCER_TELEMETRY_HEADER)
    if not header_value then
        return
    end

    header_value = ngx.decode_base64(header_value)
    local split_header_value = string_split(header_value, ':')
    if #split_header_value ~= 2 then
        px_logger.debug('Malformed x-px-enforcer-telemetry header: ' .. header)
    end
    local timestamp = split_header_value[0]
    local hmac = split_header_value[1]
    local generated_hmac = hmac('sha256', px_config.cookie_secret, timestamp)
    if hmac == generated_hmac then
        px_logger.debug('Received command to send enforcer telemetry')
        local details = {}
		details.px_config = px_commom_utils.filter_config(px_config);
		details.update_reason = 'command'
        px_client.send_enforcer_telmetry(details);
    else
        px_logger.debug('Malformed x-px-enforcer-telemetry header: ' .. header)
    end
end

return M