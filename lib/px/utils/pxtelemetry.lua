local px_common_utils = require('px.utils.pxcommonutils')
local px_constants = require('px.utils.pxconstants')

local M = {}

function M.telemetry_check_header(px_config, px_client, px_headers, px_logger)
    local header_value = px_headers.get_header(px_constants.ENFORCER_TELEMETRY_HEADER)
    if not header_value then
        return
    end

    header_value = ngx.decode_base64(header_value)
    local split_header_value = string.split(header_value, ':')
    if #split_header_value ~= 2 then
        px_logger.debug('Malformed x-px-enforcer-telemetry header: ' .. header_value)
    end
    local timestamp = split_header_value[1]
    local hmac = split_header_value[2]
    local hmac = require "resty.nettle.hmac"
    local generated_hmac = hmac('sha256', px_config.cookie_secret, timestamp)
    if hmac == generated_hmac then
        px_logger.debug('Received command to send enforcer telemetry')
        local details = {}
		details.px_config = px_common_utils.filter_config(px_config);
		details.update_reason = 'command'
        px_client.send_enforcer_telmetry(details);
    else
        px_logger.debug('Malformed x-px-enforcer-telemetry header: ' .. header_value)
    end
end

return M