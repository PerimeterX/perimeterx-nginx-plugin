---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.4
-- Release date: 07.11.2016
----------------------------------------------
local _M = {}

function _M.load(config_file)

    -- localized config
    local px_config = require (config_file)
    local px_logger = require ("px.utils.pxlogger").load(config_file)
    local cookie_secret = px_config.cookie_secret
    local string_gsub = string.gsub
    local string_format = string.format
    local string_byte = string.byte
    local hmac = require "resty.nettle.hmac"
    local score_header_enabled = px_config.score_header_enabled
    local score_header = px_config.score_header_name
    local ngx_req_clear_header = ngx.req.clear_header
    local ngx_req_set_header = ngx.req.set_header
    local ngx_req_get_headers = ngx.req.get_headers

    -- to_hex --
    -- takes one argument - a string
    -- returns one value - a hex formated representation of the string bytes
    local function to_hex(str)
        return (string_gsub(str, "(.)", function(c)
            return string_format("%02X%s", string_byte(c), "")
        end))
    end

    local function header_token()
        local remote_addr = ngx.var.remote_addr or ""
        local user_agent = ngx.var.http_user_agent or ""
        local data = remote_addr .. user_agent
        local digest = hmac("sha256", cookie_secret, data)
        return to_hex(digest)
    end

    function _M.validate_internal_request()
        local px_internal = ngx_req_get_headers()['px_internal']
        if px_internal and px_internal == header_token() then
            px_logger.debug('Request is internal. PerimeterX processing skipped.')
            return true
        end
        ngx.req.set_header('px_internal', header_token())
    end

    function _M.clear_protected_headers()
        local protected_headers = { score_header }
        for i=1, #protected_headers do
            ngx_req_clear_header(protected_headers[i])
        end
    end

    function _M.set_score_header(score)
        if score_header_enabled then
            ngx_req_set_header(score_header, score)
            return
        else
            return
        end
    end

    return _M
end
return _M
