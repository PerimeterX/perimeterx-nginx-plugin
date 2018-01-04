----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------

local _M = {}

_M.px_enabled = true

-- ##  Configuration Block ##

-- ## Required Parameters ##
_M.px_appId = 'PXvRfnOj4y'
_M.cookie_secret = 'jm6XgPXeArcrW41Bb1U2tBGW30zl08gsJy5m8avhg6dMugo6vIr9cnppRbj6rHHG'
_M.auth_token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzY29wZXMiOlsicmlza19zY29yZSIsInJlc3RfYXBpIl0sImlhdCI6MTUxNDIwNjc1NSwic3ViIjoiUFh2UmZuT2o0eSIsImp0aSI6IjI4MmJkZTliLThlOTktNGNkMy04ZDg4LTUzODdiMjllOThlYyJ9.O2V7oU2nU0cuEeNK1YrX23OO-PTAtMP0zYKOB8YYR1g'

-- ## Blocking Parameters ##
_M.blocking_score = 100
_M.block_enabled = true
_M.captcha_enabled = true

-- ## Additional Configuration Parameters ##
_M.sensitive_headers = {'cookie', 'cookies'}
_M.ip_headers = {}
_M.score_header_name = 'X-PX-SCORE'
_M.sensitive_routes_prefix = {}
_M.sensitive_routes_suffix = {}
_M.captcha_provider = "reCaptcha"
_M.additional_activity_handler = nil
_M.enabled_routes = {}
_M.first_party_enabled = true


-- ## Blocking Page Parameters ##
_M.custom_logo = nil
_M.css_ref = nil
_M.js_ref = nil

-- ## Dynamic Configuration Block ##
_M.dynamic_configurations = false
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
_M.px_port = 8080
_M.ssl_enabled = false
_M.enable_server_calls = true
_M.send_page_requested_activity = true
--_M.base_url = string.format('sapi-%s.perimeterx.net', _M.px_appId)
_M.base_url = "10.20.1.217"
--_M.collector_host = string.format('collector-%s.perimeterx.net', _M.px_appId)
_M.collector_host = '10.20.1.217'
_M.client_host = "client.perimeterx.net"
_M.collector_port_overide = 8080
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

return _M
