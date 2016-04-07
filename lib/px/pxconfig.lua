----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.5.0
-- Release date: 05.04.2016
----------------------------------------------

local _M = {}

-- ##  Configuration Block ##
_M.px_token = 'my_temporary_token'
_M.px_appId = 'PX3tHq532g'
_M.px_server = '10.0.2.2'
_M.px_port = 9090
_M.ssl_enabled = false
_M.cookie_lifetime = 3600 -- cookie lifetime, value in seconds
_M.px_debug = false
_M.px_maxbuflen = 500
_M.nginx_collect_path = '/api/v1/collector/nginxcollect'
_M.risk_score_api_path = '/api/v1/risk'
-- -- ## END - Configuration block ##

return _M
