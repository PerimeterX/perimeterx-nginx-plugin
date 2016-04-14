----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.5.0
-- Release date: 05.04.2016
----------------------------------------------

local _M = {}

-- ##  Configuration Block ##
_M.px_appId = 'PX5XgrlbMv'
_M.px_server = 'collector.a.pxi.pub'
_M.px_port = 443
_M.ssl_enabled = true
_M.cookie_lifetime = 3600 -- cookie lifetime, value in seconds
_M.cookie_encrypted = false
_M.enable_server_calls = true
_M.enable_javascript_challenge = true
_M.cookie_secret = 'Eo8pu/vR98z49YzNo6aD9fD6pO2bTXVnoc9V+5aPOH1L03u1Fa9ykqrNePGtieLY'
_M.auth_token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzY29wZXMiOlsicmlza19zY29yZSIsInJlc3RfYXBpIl0sImlhdCI6MTQ2MDYzMjQ0Niwic3ViIjoiUFg1WGdybGJNdiIsImp0aSI6IjgwOWVmMGYyLTgwMGMtNDYxMy1iNTQwLTYxMmE0ZWE0Njk0NiJ9.84AAR52EsY3_wy6dmZwIh3B__2jLRnamwGm_8eQW8jM'
_M.blocking_score = 60
_M.px_debug = false
_M.px_maxbuflen = 500
_M.nginx_collector_path = '/api/v1/collector/nginxcollect'
_M.risk_api_path = '/api/v1/risk'
-- -- ## END - Configuration block ##

return _M
