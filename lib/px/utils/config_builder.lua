local _M = {}
local PX_DEFAULT_CONFIGURATIONS  = {}
local PX_REQUIRED_FIELDS= {"px_appId", "cookie_secret", "auth_token"}

PX_DEFAULT_CONFIGURATIONS["px_enabled"] = { true, "boolean"}
PX_DEFAULT_CONFIGURATIONS["px_appId"] = { nil, "string"}
PX_DEFAULT_CONFIGURATIONS["cookie_secret"] = { nil, "string"}
PX_DEFAULT_CONFIGURATIONS["auth_token"] = { nil, "string"}
PX_DEFAULT_CONFIGURATIONS["blocking_score"] = { 100, "number"}
PX_DEFAULT_CONFIGURATIONS["block_enabled"] = { false, "boolean"}
PX_DEFAULT_CONFIGURATIONS["sensitive_headers"] = { {"cookie", "cookies"}, "table"}
PX_DEFAULT_CONFIGURATIONS["ip_headers"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["score_header_name"] = { "X-PX-SCORE", "string"}
PX_DEFAULT_CONFIGURATIONS["score_header_enabled"] = { false, "boolean"}
PX_DEFAULT_CONFIGURATIONS["sensitive_routes_prefix"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["sensitive_routes_suffix"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["sensitive_routes"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["custom_sensitive_routes"] = { nil, "function"}
PX_DEFAULT_CONFIGURATIONS["additional_activity_handler"] = { nil, "function" }
PX_DEFAULT_CONFIGURATIONS["enrich_custom_parameters"] = { nil, "function" }
PX_DEFAULT_CONFIGURATIONS["enabled_routes"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["custom_enabled_routes"] = { nil, "function"}
PX_DEFAULT_CONFIGURATIONS["monitored_routes"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["advanced_blocking_response"] = { true, "boolean"}
PX_DEFAULT_CONFIGURATIONS["first_party_enabled"] = { true, "boolean"}
PX_DEFAULT_CONFIGURATIONS["reverse_xhr_enabled"] = { true, "boolean"}
PX_DEFAULT_CONFIGURATIONS["pxhd_secure_enabled"] = { false, "boolean"}
PX_DEFAULT_CONFIGURATIONS["first_party_prefix"] = { nil, "string"}
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
PX_DEFAULT_CONFIGURATIONS["client_port_overide"] = { nil, "number"}
PX_DEFAULT_CONFIGURATIONS["proxy_url"] = { nil, "string"}
PX_DEFAULT_CONFIGURATIONS["proxy_authorization"] = { nil, "string"}
PX_DEFAULT_CONFIGURATIONS["whitelist_uri_full"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["whitelist_uri_pattern"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["whitelist_uri_prefixes"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["whitelist_uri_suffixes"] = { {'.css', '.bmp', '.tif', '.ttf', '.docx', '.woff2', '.js', '.pict', '.tiff', '.eot', '.xlsx', '.jpg', '.csv', '.eps', '.woff', '.xls', '.jpeg', '.doc', '.ejs', '.otf', '.pptx', '.gif', '.pdf', '.swf', '.svg', '.ps', '.ico', '.pls', '.midi', '.svgz', '.class', '.png', '.ppt', '.mid', '.webp', '.jar'}, "table"}
PX_DEFAULT_CONFIGURATIONS["whitelist_ip_addresses"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["whitelist_ua_full"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["whitelist_ua_sub"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["custom_cookie_header"] = { 'X-PX-COOKIES', "string"}
PX_DEFAULT_CONFIGURATIONS["bypass_monitor_header"] = { nil, "string"}
PX_DEFAULT_CONFIGURATIONS["postpone_page_requested"] = { false, "boolean"}
PX_DEFAULT_CONFIGURATIONS["hypesale_host"] = { "https://captcha.px-cdn.net", "string"}
PX_DEFAULT_CONFIGURATIONS["px_sensitive_graphql_operation_types"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["px_sensitive_graphql_operation_names"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["px_graphql_routes"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["px_enable_login_creds_extraction"] = { false, "boolean"}
PX_DEFAULT_CONFIGURATIONS["px_login_creds_settings_filename"] = { nil, "string"}
PX_DEFAULT_CONFIGURATIONS["px_login_creds_settings"] = { nil, "table"}
PX_DEFAULT_CONFIGURATIONS["px_compromised_credentials_header_name"] = { "px-compromised-credentials", "string"}
PX_DEFAULT_CONFIGURATIONS["px_login_successful_reporting_method"] = { "none", "string"}
PX_DEFAULT_CONFIGURATIONS["px_login_successful_header_name"] = { "x-px-login-successful", "string"}
PX_DEFAULT_CONFIGURATIONS["px_login_successful_status"] = { {200}, "table"}
PX_DEFAULT_CONFIGURATIONS["px_send_raw_username_on_additional_s2s_activity"] = { false, "boolean"}
PX_DEFAULT_CONFIGURATIONS["px_credentials_intelligence_version"] = { "v2", "string"}
PX_DEFAULT_CONFIGURATIONS["px_additional_s2s_activity_header_enabled"] = { false, "boolean"}
PX_DEFAULT_CONFIGURATIONS["custom_login_successful"] = { nil, "function" }
PX_DEFAULT_CONFIGURATIONS["px_login_successful_header_value"] = { "1", "string"}
PX_DEFAULT_CONFIGURATIONS["px_jwt_cookie_name"] = { nil, "string"}
PX_DEFAULT_CONFIGURATIONS["px_jwt_cookie_user_id_field_name"] = { nil, "string"}
PX_DEFAULT_CONFIGURATIONS["px_jwt_cookie_additional_field_names"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["px_jwt_header_name"] = { nil, "string"}
PX_DEFAULT_CONFIGURATIONS["px_jwt_header_user_id_field_name"] = { nil, "string"}
PX_DEFAULT_CONFIGURATIONS["px_jwt_header_additional_field_names"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["px_cors_support_enabled"] = { false, "boolean"}
PX_DEFAULT_CONFIGURATIONS["px_cors_preflight_request_filter_enabled"] = { false, "boolean"}
PX_DEFAULT_CONFIGURATIONS["px_cors_custom_preflight_handler"] = { nil, "function"}
PX_DEFAULT_CONFIGURATIONS["px_cors_create_custom_block_response_headers"] = { nil, "function"}

function _M.load(px_config)
    local px_constants = require("px.utils.pxconstants")
    local ngx_log = ngx.log
    local ngx_ERR = ngx.ERR

    -- Check the correct values from input configurations
    for k, v in pairs(px_config) do
        if PX_DEFAULT_CONFIGURATIONS[k] and type(v) ~= PX_DEFAULT_CONFIGURATIONS[k][2] then
            ngx_log(ngx_ERR, "[PerimeterX - ERROR] - " .. k .. " was assigned the wrong value, expected " .. PX_DEFAULT_CONFIGURATIONS[k][2])
        end
    end

    -- Add default configuration
    for k, v in pairs(PX_DEFAULT_CONFIGURATIONS) do
      if px_config[k] == nil then
          px_config[k] = PX_DEFAULT_CONFIGURATIONS[k][1]
      end
    end

    -- Check for missing required fields
    for k, v in pairs(PX_REQUIRED_FIELDS) do
        if (px_config[v] == nil) then
            ngx_log(ngx_ERR, "[PerimeterX - ERROR] - Missing required field: " .. v .. ". PX module will not be loaded.")
            px_config["px_enabled"] = false
        end
    end

    -- Adjust default base_url and collector_host
    if px_config["px_enabled"] == true then
        if px_config["base_url"] == "sapi.perimeterx.net" then
            px_config["base_url"] = string.format('sapi-%s.perimeterx.net', px_config["px_appId"])
        end

        if px_config["collector_host"] == "collector.perimeterx.net" then
            px_config["collector_host"] = string.format('collector-%s.perimeterx.net', px_config["px_appId"])
        end
    end

    -- set default GraphQL route
    if next(px_config.px_graphql_routes) == nil then
        table.insert(px_config.px_graphql_routes, px_constants.GRAPHQL_PATH)
    end

    return px_config
end

return _M
