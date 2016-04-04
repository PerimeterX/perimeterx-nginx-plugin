----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.5.0
-- Release date: 05.04.2016
----------------------------------------------

local _M = {}

-- ##  Configuration Block ##
_M.px_token = 'my_temporary_token'
_M.px_appId = 'PX3tHq532g'
_M.px_server = 'collector.a.pxi.pub'
_M.px_port = 443
_M.ssl_enabled = true
_M.cookie_lifetime = 3600 -- cookie lifetime, value in seconds
_M.px_debug = false
_M.px_maxbuflen = 500
_M.nginx_collect_path = '/api/v1/collector/nginxcollect'
-- -- ## END - Configuration block ##

return _M
