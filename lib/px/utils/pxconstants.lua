----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------

local _M = {
    MODULE_VERSION = "NGINX Module v4.0.0",
    RISK_PATH = "/api/v2/risk",
    CAPTCHA_PATH = "/api/v2/risk/captcha",
    ACTIVITIES_PATH = "/api/v1/collector/s2s",
    TELEMETRY_PATH = "/api/v2/risk/telemetry",
    REMOTE_CONFIGURATIONS_PATH = "/api/v1/enforcer",
    ENFORCER_TRUE_IP_HEADER = 'x-px-enforcer-true-ip',
    FIRST_PARTY_HEADER = 'x-px-first-party',
    FIRST_PARTY_VENDOR_PATH = '/init.js',
    FIRST_PARTY_XHR_PATH = '/xhr',
    FIRST_PARTY_CAPTCHA_PATH = '/captcha',
    EMPTY_GIF_B64 = 'R0lGODlhAQABAPAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==',
}

return _M
