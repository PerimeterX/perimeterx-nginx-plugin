----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------

local _M = {}

_M.px_enabled = true

-- ## Required Parameters ##
_M.px_appId = 'PX_APP_ID'
_M.cookie_secret = 'COOKIE_KEY'
_M.auth_token = 'PX_AUTH_TOKEN'

-- ## Blocking Parameters ##
-- _M.blocking_score = 100
-- _M.block_enabled = false
-- _M.advanced_blocking_response = true

-- ## Additional Configuration Parameters ##
-- _M.sensitive_headers = {'cookie', 'cookies'}
-- _M.ip_headers = {}
-- _M.score_header_name = 'X-PX-SCORE'
-- _M.sensitive_routes_prefix = {}
-- _M.sensitive_routes_suffix = {}
-- _M.sensitive_routes = {}
-- _M.custom_sensitive_routes = nil
-- _M.additional_activity_handler = nil
-- _M.enabled_routes = {}
-- _M.custom_enabled_routes = nil
-- _M.monitored_routes = {}
-- _M.first_party_enabled = true
-- _M.reverse_xhr_enabled = true
-- _M.proxy_url = nil
-- _M.proxy_authorization = nil
-- _M.custom_cookie_header = 'X-PX-COOKIES'
-- _M.bypass_monitor_header = nil
-- _M.pxhd_secure_enabled = false

-- -- ## API protection mode ##
-- _M.api_protection_mode = false
-- _M.api_protection_block_url = nil
-- _M.api_protection_default_redirect_url = nil

-- -- ## Blocking Page Parameters ##
-- _M.custom_logo = nil
-- _M.css_ref = nil
-- _M.js_ref = nil

-- ## Dynamic Configuration Block ##
-- _M.dynamic_configurations = false
-- _M.configuration_server = 'px-conf.perimeterx.net'
-- _M.configuration_server_port = 443
-- _M.load_interval = 5

-- _M.custom_block_url = nil
-- _M.redirect_on_custom_url = false
-- _M.redirect_to_referer = false

-- ## Debug Parameters ##
-- _M.px_debug = false
-- _M.s2s_timeout = 1000
-- _M.client_timeout = 2000
-- _M.cookie_encrypted = true
-- _M.px_maxbuflen = 10
-- _M.px_port = 443
-- _M.ssl_enabled = true
-- _M.enable_server_calls = true
-- _M.send_page_requested_activity = true
-- _M.base_url = string.format('sapi-%s.perimeterx.net', _M.px_appId)
-- _M.collector_host = string.format('collector-%s.perimeterx.net', _M.px_appId)
-- _M.client_host = "client.perimeterx.net"
-- _M.collector_port_overide = nil
-- _M.client_port_overide = nil

-- ## Filter Configuration ##
-- _M.whitelist_uri_full = {}
-- _M.whitelist_uri_prefixes = {}
-- _M.whitelist_uri_suffixes = {'.css', '.bmp', '.tif', '.ttf', '.docx', '.woff2', '.js', '.pict', '.tiff', '.eot', '.xlsx', '.jpg', '.csv', '.eps', '.woff', '.xls', '.jpeg', '.doc', '.ejs', '.otf', '.pptx', '.gif', '.pdf', '.swf', '.svg', '.ps', '.ico', '.pls', '.midi', '.svgz', '.class', '.png', '.ppt', '.mid', '.webp', '.jar'}
-- _M.whitelist_ip_addresses = {}
-- _M.whitelist_ua_full = {}
-- _M.whitelist_ua_sub = {}

-- ## Login Credentials extraction
--_M.px_enable_login_creds_extraction = false
--_M.px_login_creds_settings_filename = nil
--_M.px_compromised_credentials_header_name = "px-compromised-credentials"
--_M.px_login_successful_reporting_method = "none"
--_M.px_login_successful_header_name = "x-px-login-successful"
--_M.px_login_successful_status = { 200 }
--_M.px_send_raw_username_on_additional_s2s_activity = false
--_M.px_credentials_intelligence_version = "v1"
--_M.px_additional_s2s_activity_header_enabled = false
--_M.custom_login_successful = nil


-- ## Page Requested Settings
-- postpone_page_requested: if true then finalize() must be called from header_filter_by_lua_block to finalize the request processing
-- _M.postpone_page_requested = false

-- ## GraphQL
-- _M.px_sensitive_graphql_operation_types = {}
-- _M.px_sensitive_graphql_operation_names = {}
-- _M.px_graphql_paths = {'/graphql'}

-- ## User Identifiers
-- _M.px_jwt_cookie_name = nil
-- _M.px_jwt_cookie_user_id_field_name = nil
-- _M.px_jwt_cookie_additional_field_names = {}
-- _M.px_jwt_header_name = nil
-- _M.px_jwt_header_user_id_field_name = nil
-- _M.px_jwt_header_additional_field_names = {}
return _M
