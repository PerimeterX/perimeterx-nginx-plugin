local _M = {}
local PX_DEFUALT_CONSTANT_CONFIGURATION = {}
local PX_DEFAULT_CONFIGURATIONS  = {}
local PX_REQUIRED_FIELDS= {"px_appId", "cookie_secret", "auth_token"}

function _M.Load(userConfiguration)
    local pxConfig = {}

    function initConfigurations()
        PX_DEFUALT_CONSTANT_CONFIGURATION["MODULE_VERSION"] = "NGINX Module v3.3.0"
        PX_DEFAULT_CONFIGURATIONS["px_enabled"] = { true, "boolean"}
        PX_DEFAULT_CONFIGURATIONS["px_appId"] = { nil, "string"}
        PX_DEFAULT_CONFIGURATIONS["cookie_secret"] = { nil, "string"}
        PX_DEFAULT_CONFIGURATIONS["auth_token"] = { nil, "string"}
        PX_DEFAULT_CONFIGURATIONS["blocking_score"] = { 100, "number"}
        PX_DEFAULT_CONFIGURATIONS["block_enabled"] = { false, "boolean"}
        PX_DEFAULT_CONFIGURATIONS["sensitive_headers"] = { {"cookie", "cookies"}, "table"}
        PX_DEFAULT_CONFIGURATIONS["ip_headers"] = { {}, "table"}
        PX_DEFAULT_CONFIGURATIONS["score_header_name"] = { "X-PX-SCORE", "string"}
        PX_DEFAULT_CONFIGURATIONS["sensitive_routes_prefix"] = { {}, "table"}
        PX_DEFAULT_CONFIGURATIONS["sensitive_routes_suffix"] = { {}, "table"}
        PX_DEFAULT_CONFIGURATIONS["captcha_provider"] = { "reCaptcha", "string"}
        PX_DEFAULT_CONFIGURATIONS["additional_activity_handler"] = { nil, "function"}
        PX_DEFAULT_CONFIGURATIONS["enabled_routes"] = { {}, "table"}
        PX_DEFAULT_CONFIGURATIONS["first_party_enabled"] = { true, "boolean"}
        PX_DEFAULT_CONFIGURATIONS["reverse_xhr_enabled"] = { true, "boolean"}
        PX_DEFAULT_CONFIGURATIONS["api_protection_mode"] = { false, "boolean"}
        PX_DEFAULT_CONFIGURATIONS["api_protection_block_url"] = { nil, "string"}
        PX_DEFAULT_CONFIGURATIONS["api_protection_default_redirect_url"] = { nil, "string"}
        PX_DEFAULT_CONFIGURATIONS["custom_logo"] = { nil, "string"}
        PX_DEFAULT_CONFIGURATIONS["css_ref"] = { nil, "string"}
        PX_DEFAULT_CONFIGURATIONS["js_ref"] = { nil, "string"}
        PX_DEFAULT_CONFIGURATIONS["dynamic_configurations"] = { false, "boolean"}
        PX_DEFAULT_CONFIGURATIONS["configuration_server"] = { "px-conf.perimeterx.net", "string"}
        PX_DEFAULT_CONFIGURATIONS["configuration_server_port"] = { 443, "number"}
        PX_DEFAULT_CONFIGURATIONS["load_interval"] = { 5, "number"}
        PX_DEFAULT_CONFIGURATIONS["custom_block_url"] = { nil, "string"}
        PX_DEFAULT_CONFIGURATIONS["redirect_on_custom_url"] = { false, "boolean"}
        PX_DEFAULT_CONFIGURATIONS["px_debug"] = { false, "boolean"}
        PX_DEFAULT_CONFIGURATIONS["s2s_timeout"] = { 1000, "number"}
        PX_DEFAULT_CONFIGURATIONS["client_timeout"] = { 2000, "number"}
        PX_DEFAULT_CONFIGURATIONS["cookie_encrypted"] = { true, "boolean"}
        PX_DEFAULT_CONFIGURATIONS["px_maxbuflen"] = { 10, "number"}
        PX_DEFAULT_CONFIGURATIONS["px_port"] = { 443, "number"}
        PX_DEFAULT_CONFIGURATIONS["ssl_enabled"] = { true, "boolean"}
        PX_DEFAULT_CONFIGURATIONS["enable_server_calls"] = { true, "boolean"}
        PX_DEFAULT_CONFIGURATIONS["send_page_requested_activity"] = { true, "boolean"}
        PX_DEFAULT_CONFIGURATIONS["base_url"] = { "sapi.perimeterx.net", "string"}
        PX_DEFAULT_CONFIGURATIONS["collector_host"] = { "collector.perimeterx.net", "string"}
        PX_DEFAULT_CONFIGURATIONS["client_host"] = { "client.perimeterx.net", "string"}
        PX_DEFAULT_CONFIGURATIONS["captcha_script_host"] = { "captcha.px-cdn.net", "string"}
        PX_DEFAULT_CONFIGURATIONS["collector_port_overide"] = { nil, "number"}
        PX_DEFAULT_CONFIGURATIONS["client_port_overide"] = { 443, "number"}
        PX_DEFAULT_CONFIGURATIONS["whitelist"] = { {
            uri_full = { _M.custom_block_url },
            uri_prefixes = {},
            uri_suffixes = { '.css', '.bmp', '.tif', '.ttf', '.docx', '.woff2', '.js', '.pict', '.tiff', '.eot', '.xlsx', '.jpg', '.csv', '.eps', '.woff', '.xls', '.jpeg', '.doc', '.ejs', '.otf', '.pptx', '.gif', '.pdf', '.swf', '.svg', '.ps', '.ico', '.pls', '.midi', '.svgz', '.class', '.png', '.ppt', '.mid', 'webp', '.jar' },
            ip_addresses = {},
            ua_full = {},
            ua_sub = {}
        }, "table"}
    end

    initConfigurations()

    -- Create default configuration
    for k, v in pairs(PX_DEFAULT_CONFIGURATIONS) do
      pxConfig[k] = PX_DEFAULT_CONFIGURATIONS[k]
    end

    -- Override with user defined configuration
    for k, v in pairs(userConfiguration) do
        if PX_DEFAULT_CONFIGURATIONS[k] and type(_M[k]) ~= PX_DEFAULT_CONFIGURATIONS[k][2] then
            print(k .. " was assigned the wrong value, expected " .. PX_DEFAULT_CONFIGURATIONS[k][2])
        else
            pxConfig[k] = PX_DEFAULT_CONFIGURATIONS[k][1]
        end
    end

    -- Add the constants
    for k, v in pairs(PX_DEFUALT_CONSTANT_CONFIGURATION) do
      pxConfig[k] = PX_DEFUALT_CONSTANT_CONFIGURATION[k]
    end

    -- Check for missing required fields
    for k, v in pairs(PX_REQUIRED_FIELDS) do
        if (pxConfig[v] == nil) then
            print("Missing required field: " .. v .. ", PX module will not be loaded.")
            pxConfig["px_enabled"] = false
        end
    end

    return pxConfig
end

return _M