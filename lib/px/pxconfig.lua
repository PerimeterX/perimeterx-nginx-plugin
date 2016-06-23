----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.5.0
-- Release date: 05.04.2016
----------------------------------------------

local _M = {}

_M.px_enabled = true

-- ##  Configuration Block ##
_M.px_appId = 'APP_ID'
_M.cookie_secret = 'COOKIE_SECRET'
_M.auth_token = 'JWT_AUTH_TOKEN'
_M.blocking_score = 60
_M.cookie_encrypted = true
_M.enable_server_calls = true
_M.send_page_requested_activity = false
_M.block_enabled = true
_M.captcha_enabled = true
_M.score_header_name = 'X-PX-SCORE'
_M.score_header_enabled = false
_M.px_debug = false

_M.s2s_timeout = 1000
_M.px_maxbuflen = 10
_M.px_server = 'collector.perimeterx.net'
_M.px_port = 443
_M.ssl_enabled = true
_M.nginx_collector_path = '/api/v1/collector/s2s'
_M.risk_api_path = '/api/v1/risk'
_M.captcha_api_path = '/api/v1/risk/captcha'
_M.enabled_routes = {}
-- -- ## END - Configuration block ##

return _M
