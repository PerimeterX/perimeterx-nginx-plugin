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
    local px_constants = require "px.utils.pxconstants"

    local cjson = require "cjson"
    local string_gmatch = string.gmatch
    local auth_token = px_config.auth_token
    local captcha_api_path = px_constants.CAPTCHA_PATH
    local pcall = pcall
    local ngx_req_get_headers = ngx.req.get_headers

    -- split_captcha --
    -- takes one argument - a value of pxCaptcha (vid:captcha)
    -- returns two values - vid and captcha
    local function split_cookie(cookie)
        local a = {}
        local b = 1
        for i in string_gmatch(cookie, "[^:]+") do
            a[b] = i
            b = b + 1
        end
        return a[1], a[2], a[3]
    end

    -- new_request_object --
    -- takes no arguments
    -- returns table
    local function new_captcha_request_object(captcha, vid, uuid)
        px_logger.debug('New CAPTCHA request')

        local captcha_reset = {}
        captcha_reset.cid = ''
        captcha_reset.request = {}
        captcha_reset.request.ip = ngx.var.remote_addr
        captcha_reset.request.uri = ngx.var.uri
        captcha_reset.request.headers = {}
        local h = ngx_req_get_headers()
        for k, v in pairs(h) do
            captcha_reset.request.headers[#captcha_reset.request.headers + 1] = { ['name'] = k, ['value'] = v }
        end
        captcha_reset.pxCaptcha = captcha;
        captcha_reset.hostname = ngx.var.host;
        if vid and uuid then
            captcha_reset.vid = vid
            captcha_reset.uuid = uuid
        else
            px_logger.error('VID and UUID not present for CAPTCHA. VID and UUID are required. Please check risk cookie policy')
        end

        px_logger.debug('CAPTCHA object completed')
        return captcha_reset
    end

    function _M.process(captcha)
        if not captcha then
            px_logger.debug('CAPTCHA object is nil');
            return -1;
        end
        px_logger.debug('Processing new CAPTCHA object');

        local _captcha, vid, uuid = split_cookie(captcha)
        if not _captcha or not vid or not uuid then
            px_logger.debug('CAPTCHA content is not valid');
            return -1;
        end

        px_logger.debug('CAPTCHA value: ' .. _captcha);
        px_logger.debug('uuid value: ' .. uuid);

        local request_data = new_captcha_request_object(_captcha, vid, uuid)
        local success, response = pcall(px_api.call_s2s, request_data, captcha_api_path, auth_token)
        if success then
            return response.status
        else
            px_logger.error("Failed to connecto CAPTCHA API: " .. cjson.encode(response))
        end
        return -1;
    end

    return _M
end

return M