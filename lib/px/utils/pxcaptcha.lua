---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.4
-- Release date: 07.11.2016
----------------------------------------------

local M = {}

function M.load(config_file)
    local _M = {}

    local px_config = require(config_file)
    local px_api = require("px.utils.pxapi").load(config_file)
    local px_logger = require("px.utils.pxlogger").load(config_file)
    local px_headers = require("px.utils.pxheaders").load(config_file)
    local px_constants = require "px.utils.pxconstants"
    local px_common_utils = require "px.utils.pxcommonutils"

    local auth_token = px_config.auth_token
    local captcha_api_path = px_constants.CAPTCHA_PATH
    local pcall = pcall

    local ngx_req_get_headers = ngx.req.get_headers
    local function split_s(str, delimiter)
        local result = {}
        local from = 1
        local delim_from, delim_to = string.find(str, delimiter, from)
        while delim_from do
            table.insert(result, string.sub(str, from, delim_from - 1))
            from = delim_to + 1
            delim_from, delim_to = string.find(str, delimiter, from)
        end
        table.insert(result, string.sub(str, from))
        return result
    end

    -- new_request_object --
    -- takes no arguments
    -- returns table
    local function new_captcha_request_object(captcha)
        px_logger.debug('New CAPTCHA request')

        local captcha_reset = {}
        captcha_reset.cid = ''
        captcha_reset.request = {}
        captcha_reset.request.ip = px_headers.get_ip()
        captcha_reset.request.uri = ngx.var.uri
        captcha_reset.request.captchaType = px_config.captcha_provider
        captcha_reset.request.headers = {}
        local h = ngx_req_get_headers()
        for k, v in pairs(h) do
            captcha_reset.request.headers[#captcha_reset.request.headers + 1] = { ['name'] = k, ['value'] = v }
        end
        captcha_reset.pxCaptcha = captcha;
        captcha_reset.hostname = ngx.var.host;

        px_logger.debug('CAPTCHA object completed')
        return captcha_reset
    end

    function _M.process(captcha)
        if not captcha then
            px_logger.debug('CAPTCHA object is nil');
            return -1;
        end
        px_logger.debug('Processing new CAPTCHA object');

        local request_data = new_captcha_request_object(captcha)
        px_logger.debug('Sending Captcha API call to eval cookie');
        local start_risk_rtt = px_common_utils.get_time_in_milliseconds()
        local success, response = pcall(px_api.call_s2s, request_data, captcha_api_path, auth_token)
        ngx.ctx.risk_rtt =  px_common_utils.get_time_in_milliseconds() - start_risk_rtt
        if success then
            px_logger.debug('Captcha API call successfully returned');
            ngx.ctx.pass_reason = 'captcha'
            return response.status
        elseif string.match(response,'timeout') then
            px_logger.error('captcha timeout')
            ngx.ctx.pass_reason = 'captcha_timeout'
            return 0
        end
        px_logger.error("Failed to process CAPTCHA, passing request: " .. cjson.encode(response))
        return 0;
    end

    return _M
end

return M