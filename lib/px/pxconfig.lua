----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.5.0
-- Release date: 05.04.2016
----------------------------------------------

local _M = {}

_M.px_enabled = true

-- ##  Configuration Block ##
_M.px_appId = 'PXvRfnOj4y'
_M.cookie_secret = 'f7pwHxYoDYC9JxHxDK9sreWi5uNCdWB/HXaFN6CS8uL9smhsAQRNGooDzIqrlxoS'
_M.auth_token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzY29wZXMiOlsicmlza19zY29yZSIsInJlc3RfYXBpIl0sImlhdCI6MTQ3MjE3NTkxNiwic3ViIjoiUFh2UmZuT2o0eSIsImp0aSI6IjgzMDJmNDRhLTgwNTktNDRkZi05ZGJkLWRhZWRjNzE1NjhmNyJ9.giB48Fl02FFhLw15UujLVzq8Q7PRhweBC_wCtweXerU'
_M.blocking_score = 60
_M.cookie_encrypted = true
_M.enable_server_calls = true
_M.send_page_requested_activity = true
_M.block_enabled = true
_M.captcha_enabled = true
_M.px_debug = true

_M.s2s_timeout = 1000
_M.px_maxbuflen = 10
_M.score_header_name = 'X-PX-SCORE'
_M.px_port = 443
_M.ssl_enabled = true
_M.custom_block_url = nil
_M.enabled_routes = {}
_M.custom_logo = nil
_M.css_ref = nil
_M.js_ref = nil
-- -- ## END - Configuration block ##

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
