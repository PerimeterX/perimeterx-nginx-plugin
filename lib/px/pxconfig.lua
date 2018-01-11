----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------

local _M = {}

_M.px_enabled = true

-- ##  Configuration Block ##

-- ## Required Parameters ##
_M.px_appId = 'PX_APP_ID'
_M.cookie_secret = 'COOKIE_KEY'
_M.auth_token = 'PX_AUTH_TOKEN'

-- ## Blocking Parameters ##
_M.blocking_score = 100
_M.block_enabled = false
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

-- ## API protection mode ##
_M.api_protection_mode = false
_M.api_protection_block_url = nil
_M.api_protection_default_redirect_url = nil

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
_M.px_debug = false
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

return _M
