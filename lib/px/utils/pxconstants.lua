----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------

local _M = {
    MODULE_VERSION = "NGINX Module v7.3.3",
    RISK_PATH = "/api/v3/risk",
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
    ENFORCER_TELEMETRY_HEADER = 'x-px-enforcer-telemetry',
    HYPE_SALE_CUSTOM_PARAM = 'is_hype_sale',
    HSC_BLOCK_ACTION = 'hsc',
    HSC_DRC_PROPERTY = 7190,
    HSC_BLOCK_TYPE = 'pxHypeSaleChallenge',
    RATE_LIMIT_ACTION = 'r',
    GRAPHQL_PATH = "^/graphql/?$",
    GRAPHQL_QUERY = "query",
    GRAPHQL_MUTATION = "mutation",
    JSON_CONTENT_TYPE = "application/json",
    URL_ENCODED_CONTENT_TYPE = "application/x-www-form-urlencoded",
    MULTIPART_FORM_CONTENT_TYPE = "multipart/form-data",
    CI_VERSION1 = "v1",
    CI_VERSION2 = "v2",
    CI_VERSION_MULTISTEP_SSO = "multistep_sso",
    ADDITIONAL_ACTIVITY_HEADER = "px-additional-activity",
    ADDITIONAL_ACTIVITY_URL_HEADER = "px-additional-activity-url",
    EMAIL_ADDRESS_REGEX = "[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?",
    GMAIL_DOMAIN = "gmail.com",
    BACKUP_CAPTCHA_HOST = "https://captcha.px-cloud.net",
    CTS_COOKIE = "pxcts",
    CORS_HEADER_KEY = "Access-Control-Allow-Origin",
    CORS_ALLOW_CREDENTIALS_HEADER_KEY = "Access-Control-Allow-Credentials",
    CORS_ACCESS_CONTROL_ALLOW_METHODS_KEY = "Access-Control-Allow-Methods",
    CORS_ACCESS_CONTROL_REQUEST_METHOD_HEADER = "Access-Control-Request-Method",
    CORS_ACCESS_CONTROL_ALLOW_METHODS_VALUE = "GET,POST,OPTIONS",
    CORS_ACCESS_CONTROL_ALLOW_HEADERS_KEY = "Access-Control-Allow-Headers",
    CORS_ACCESS_CONTROL_ALLOW_HEADERS_VALUE = "Content-Type,Authorization",
    ORIGIN_HEADER_NAME = "origin",
    OPTIONS_METHOD = "OPTIONS"

}

return _M
