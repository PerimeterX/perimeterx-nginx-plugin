----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.4
-- Release date: 07.11.2016
----------------------------------------------

local _M = {
    MODULE_VERSION = "NGINX Module v3.1.0",
    RISK_PATH = "/api/v2/risk",
    CAPTCHA_PATH = "/api/v2/risk/captcha",
    ACTIVITIES_PATH = "/api/v1/collector/s2s",
    TELEMETRY_PATH = "/api/v2/risk/telemetry",
    REMOTE_CONFIGURATIONS_PATH = "/api/v1/enforcer",
    ENFORCER_TRUE_IP_HEADER = 'x-px-enforcer-true-ip',
    FIRST_PARTY_HEADER = 'x-px-first-party'
}

return _M
