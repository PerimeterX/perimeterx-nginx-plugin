---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------

local M = {}

function M.load(px_config)
    local _M = {}

    local px_logger = require ("px.utils.pxlogger").load(px_config)
    local cjson = require "cjson"
    local px_constants = require("px.utils.pxconstants")

    _M.SUPPORTED_FEATURES = "/supported-features"
    _M.TEST_APP_CREDENTIALS = "/test-app-credentials"
    _M.POST_CONFIG = "/config"

    -- return true if request is handled
    function _M.handle_e2e_endpoints(lower_request_url)
        if not px_config.e2e_tests_enabled then
            return false
        end

        local method = ngx.req.get_method()
        method = method:lower()

        if method == "get" and lower_request_url == _M.TEST_APP_CREDENTIALS then
            px_logger.debug("Sending app credentials")
            ngx.header["Content-Type"] = 'application/json'
            local data = {}
            data["px_app_id"] = px_config.px_appId
            data["px_cookie_secret"] = px_config.cookie_secret
            ngx.print(cjson.encode(data))
            ngx.exit(ngx.OK)
            return true
        elseif method == "get" and lower_request_url == _M.SUPPORTED_FEATURES then
            px_logger.debug("Sending supported features")
            ngx.header["Content-Type"] = 'application/json'
            local data = {}
            data["version"] = px_constants.MODULE_VERSION
            local supported_features = {}
            supported_features["risk_api"]= true
            supported_features["cookie_v2"]= false
            supported_features["cookie_v3"]= true
            supported_features["page_requested"]= true
            supported_features["block"]= true
            supported_features["block_page_hard_block"]= true
            supported_features["block_page_captcha"]= true
            supported_features["block_page_rate_limit"]= false
            supported_features["logger"]= true
            supported_features["client_ip_extraction"]= true
            supported_features["module_enable"]= true
            supported_features["module_mode"]= true
            supported_features["additional_activity_handler"]= false
            supported_features["advanced_blocking_response"]= true
            supported_features["batched_activities"]= true
            supported_features["csp_support"]= true
            supported_features["pxde"]= true
            supported_features["enforced_routes"]= true
            supported_features["first_party"]= true
            supported_features["login_credentials_extraction"]= true
            supported_features["mobile_support"]= true
            supported_features["monitored_routes"]= true
            supported_features["pxhd"]= true
            supported_features["sensitive_headers"]= true
            supported_features["sensitive_routes"]= true
            supported_features["telemetry_command"]= true
            supported_features["vid_extraction"]= true
            supported_features["filter_by_extension"]= true
            supported_features["filter_by_http_method"]= false
            supported_features["filter_by_ip"]= true
            supported_features["filter_by_route"]= true
            supported_features["filter_by_user_agent"]= true
            supported_features["css_ref"]= true
            supported_features["js_ref"]= true
            supported_features["custom_cookie_header"]= false
            supported_features["custom_logo"]= true
            supported_features["custom_parameters"]= true
            supported_features["custom_proxy"]= true
            data["supported_features"] = supported_features
            ngx.print(cjson.encode(data))
            ngx.exit(ngx.OK)
            return true
        elseif method == "post" and lower_request_url == _M.POST_CONFIG then
            ngx.exit(ngx.OK)
            return true
        end

        return false
    end

    return _M
end
return M
