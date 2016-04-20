----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.5.0
-- Release date: 05.04.2016
----------------------------------------------

local _M = {}

_M.px_enabled = true

-- ##  Configuration Block ##
_M.px_appId = 'APP_ID'
_M.px_server = 'collector.a.pxi.pub'
_M.px_port = 443
_M.ssl_enabled = true
_M.cookie_lifetime = 3600 -- cookie lifetime, value in seconds
_M.cookie_encrypted = false
_M.enable_server_calls = true
_M.cookie_secret = 'COOKIE_SECRET'
_M.auth_token = 'JWT_AUTH_TOKEN'
_M.s2s_timeout = 1000
_M.send_page_requested_activity = false
_M.blocking_score = 90
_M.px_debug = false
_M.px_maxbuflen = 500
_M.nginx_collector_path = '/api/v1/collector/nginxcollect'
_M.risk_api_path = '/api/v1/risk'
-- -- ## END - Configuration block ##

return _M
