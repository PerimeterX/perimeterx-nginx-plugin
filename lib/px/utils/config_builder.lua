local _M = {}
local PX_DEFAULT_CONFIGURATIONS = {}
local PX_REQUIRED_FIELDS = {"px_appId", "cookie_secret", "auth_token"}

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
PX_DEFAULT_CONFIGURATIONS["additional_activity_handler"] = { nil, "function" }
PX_DEFAULT_CONFIGURATIONS["enrich_custom_parameters"] = { nil, "function" }
PX_DEFAULT_CONFIGURATIONS["enabled_routes"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["advanced_blocking_response"] = { true, "boolean"}
PX_DEFAULT_CONFIGURATIONS["first_party_enabled"] = { true, "boolean"}
PX_DEFAULT_CONFIGURATIONS["reverse_xhr_enabled"] = { true, "boolean"}
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
PX_DEFAULT_CONFIGURATIONS["whitelist_uri_prefixes"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["whitelist_uri_suffixes"] = { {'.css', '.bmp', '.tif', '.ttf', '.docx', '.woff2', '.js', '.pict', '.tiff', '.eot', '.xlsx', '.jpg', '.csv', '.eps', '.woff', '.xls', '.jpeg', '.doc', '.ejs', '.otf', '.pptx', '.gif', '.pdf', '.swf', '.svg', '.ps', '.ico', '.pls', '.midi', '.svgz', '.class', '.png', '.ppt', '.mid', '.webp', '.jar'}, "table"}
PX_DEFAULT_CONFIGURATIONS["whitelist_ip_addresses"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["whitelist_ua_full"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["whitelist_ua_sub"] = { {}, "table"}
PX_DEFAULT_CONFIGURATIONS["config_file_path"] = { nil, "string"}

local PX_CONFIG_FILE_MAP = {}
PX_CONFIG_FILE_MAP["px_app_id"] = "px_appId"
PX_CONFIG_FILE_MAP["px_enabled"] = "px_enabled"
PX_CONFIG_FILE_MAP["px_custom_block_page_url"] = "custom_block_url"
PX_CONFIG_FILE_MAP["px_redirect_on_custom_block_page_url"] = "redirect_on_custom_url"
PX_CONFIG_FILE_MAP["px_collector_url"] = "collector_host"
PX_CONFIG_FILE_MAP["px_client_url"] = "client_host"

local function get_dirname()
    return string.sub(debug.getinfo(1).source, 2, string.len('/utils/config_builder.lua') * -1)
end

local function load_config_file(px_config)
    local cjson = require "cjson"
    local ngx_log = ngx.log
    local ngx_ERR = ngx.ERR

    if px_config["config_file_path"] ~= nil then
        local config_file_path = px_config["config_file_path"]
        
        local file = io.open(config_file_path, "rb")
        if file == nil then
            ngx_log(ngx_ERR, "[PerimeterX - DEBUG] - unable to read config file: " .. config_file_path)
            return
        end
        local data = file:read("*all")
        file:close()

        local success, json_data = pcall(cjson.decode, data)
        if not success then
            ngx_log(ngx_ERR, "[PerimeterX - DEBUG] - error while decoding config file as json")
            return
        end

        for k, v in pairs(json_data) do
            if PX_CONFIG_FILE_MAP[k] then
                px_config[PX_CONFIG_FILE_MAP[k]] = v
            else
                if string_sub(k, 1, 3) == "px_" then
                    no_px_key = string_sub(k, 4)
                    px_config[no_px_key] = v
                end
            end
        end
    end
end

function _M.load(px_config)
    local ngx_log = ngx.log
    local ngx_ERR = ngx.ERR
    local string_sub = string.sub

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
    
    local status, err = pcall(load_config_file, px_config)
    if not status then
        ngx_log(ngx_ERR, "[PerimeterX - DEBUG] - error loading config file: " .. err)
    end

    if px_config["px_enabled"] == true then
        px_config["base_url"] = string.format('sapi-%s.perimeterx.net', px_config["px_appId"])
        px_config["collector_host"] = string.format('collector-%s.perimeterx.net', px_config["px_appId"])
    end

    return px_config
end

return _M
