----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------

local _M = {}

_M.px_enabled = true

-- ##  Configuration Block ##

-- ## Required Parameters ##
_M.px_appId = 'PXvRfnOj4y'
_M.cookie_secret = '6CS5OfTXmAZIJmpERTpLqHycYCbBK3Jk31dm0fjrrooblU8vKPe8Yqd0Q31QBezc'
_M.auth_token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzY29wZXMiOlsicmlza19zY29yZSIsInJlc3RfYXBpIl0sImlhdCI6MTUxNjA5MjE1NSwic3ViIjoiUFh2UmZuT2o0eSIsImp0aSI6IjcwMWVkOGZkLTY0OGYtNDhjMy05ZGYyLWMyMjQ4ZTFiNDQ3NiJ9.GCTz7v2sfY3BsirFMH69c_bwYMTuZoLd8lOw-LpIYgk'

-- ## Blocking Parameters ##
_M.blocking_score = 70
_M.block_enabled = true
_M.captcha_enabled = true

-- ## Additional Configuration Parameters ##
_M.sensitive_headers = { 'cookie', 'cookies' }
_M.ip_headers = { 'X-Forwarded-For' }
_M.score_header_name = 'X-PX-SCORE'
_M.sensitive_routes_prefix = { '/profile' }
_M.sensitive_routes_suffix = {}
_M.captcha_provider = "reCaptcha"
_M.additional_activity_handler = function(event_type, ctx, details)
    local ngx_say = ngx.say
    local ngx_exit = ngx.exit
    local cjson = require "cjson"


    if ngx.req.get_headers()["x-px-auto-tests"] and ngx.req.get_headers()["x-px-auto-tests"] == "bigbotsdontcry" then

        local context = {}
        context["px_cookies"] = {}
        if ngx.var.cookie__px3 then
            context["px_cookies"]["v3"] = ngx.var.cookie__px3
        end

        if ngx.var.cookie__px then
            context["px_cookies"]["v1"] = ngx.var.cookie__px
        end

        context["decoded_px_cookie"] = ngx.ctx.px_cookie or nil
        context["px_cookie_hmac"] = ngx.ctx.px_cookie_hmac or nil
        context["ip"] = _M.get_ip()
        context["px_captcha"] = ngx.ctx.px_captcha or nil
        context["http_version"] = ngx.req.http_version()
        context["http_method"] = ngx.req.get_method()
        context["headers"] = _M.filter_headers(_M.sensitive_headers)
        context["hostname"] = ngx.var.host
        context["uri"] = ngx.var.request_uri
        context["user_agent"] = ngx.var.http_user_agent
        context["full_url"] = ngx.var.scheme .. "://" .. ngx.var.host .. ngx.var.uri
        context["s2s_call_reason"] = ngx.ctx.s2s_call_reason or "none"
        context["score"] = ngx.ctx.block_score or 0
        context["vid"] = ngx.ctx.vid or nil
        context["uuid"] = ngx.ctx.uuid or nil
        context["block_reason"] = ngx.ctx.block_reason or "none"
        context["is_made_s2s_api_call"] = ngx.ctx.is_made_s2s_api_call or false
        context["block_action"] = ngx.ctx.px_action or "c"
        context["block_data"] = ngx.ctx.px_action_data or nil
        context["sensitive_route"] = ngx.ctx.s2s_call_reason == 'sensitive_route'
        context["cookie_origin"] = ngx.ctx.px_cookie_origin
        context["module_mode"] = _M.block_enabled == true and 'blocking' or 'monitoring'
        context["pxde"] = ngx.ctx.pxde and ngx.ctx.pxde or 'none'
        context["pxde_verified"] = ngx.ctx.pxde_verified ~= nil and ngx.ctx.pxde_verified or 'none'

        ngx.header["Content-Type"] = 'application/json'
        ngx_say(cjson.encode(context));
        ngx_exit(ngx.OK);
    end
end
_M.enabled_routes = {}
_M.first_party_enabled = true
_M.reverse_xhr_enabled = true

-- ## Blocking Page Parameters ##
_M.custom_logo = nil
_M.css_ref = nil
_M.js_ref = nil

-- ## Dynamic Configuration Block ##
_M.dynamic_configurations = true
_M.configuration_server = 'px-conf.perimeterx.net'
_M.configuration_server_port = 443
_M.load_interval = 5
-- ## END - Configuration block ##

_M.custom_block_url = nil
_M.redirect_on_custom_url = false


-- ## Debug Parameters ##
_M.px_debug = true
_M.s2s_timeout = 1000
_M.client_timeout = 2000
_M.cookie_encrypted = true
_M.px_maxbuflen = 10
_M.px_port = 443
_M.ssl_enabled = true
_M.enable_server_calls = true
_M.send_page_requested_activity = true
_M.base_url = string.format('sapi-%s.perimeterx.net', _M.px_appId)
_M.collector_host = string.format('collector-%s.perimeterx.net', _M.px_appId)
_M.client_host = "client.perimeterx.net"
_M.captcha_script_host = "captcha.perimeterx.net"
_M.captcha_script_port = 443
_M.collector_port_overide = nil
_M.client_port_overide = nil
-- ## END - Configuration block ##

-- ## Filter Configuration ##

_M.whitelist = {
    uri_full = { _M.custom_block_url },
    uri_prefixes = {},
    uri_suffixes = { '.css', '.bmp', '.tif', '.ttf', '.docx', '.woff2', '.js', '.pict', '.tiff', '.eot', '.xlsx', '.jpg', '.csv', '.eps', '.woff', '.xls', '.jpeg', '.doc', '.ejs', '.otf', '.pptx', '.gif', '.pdf', '.swf', '.svg', '.ps', '.ico', '.pls', '.midi', '.svgz', '.class', '.png', '.ppt', '.mid', 'webp', '.jar' },
    ip_addresses = {},
    ua_full = {},
    ua_sub = {}
}

function _M.get_ip()
    if _M.ip_headers ~= nil then
        for i, header in ipairs(_M.ip_headers) do
            if _M.get_header(header) ~= nil then
                return _M.get_header(header)
            end
        end
    end
    local ip = ngx.var.remote_addr
    return ip or ""
end

function _M.get_header(name)
    return ngx.req.get_headers()[name] or nil
end

function _M.array_index_of(array, item)
    if array == nil then
        return -1
    end

    for i, value in ipairs(array) do
        if string.lower(value) == string.lower(item) then
            return i
        end
    end
    return -1
end

function _M.filter_headers(sensitive_headers)
    local headers = ngx.req.get_headers()
    local request_headers = {}
    for k, v in pairs(headers) do
        -- filter sensitive headers
        if _M.array_index_of(sensitive_headers, k) == -1 then
            request_headers[k] = v
        end
    end

    return request_headers
end


return _M

