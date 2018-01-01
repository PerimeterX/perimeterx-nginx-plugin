use Test::Nginx::Socket::Lua 'no_plan';

log_level('debug');
run_tests();

__DATA__


=== TEST 1: Forward client request

--- http_config
    lua_package_path "/usr/local/lib/lua/?.lua;/usr/local/openresty/lualib/?.lua;;";
    lua_ssl_trusted_certificate "/etc/ssl/certs/ca-certificates.crt";
    lua_ssl_verify_depth 3;
    lua_socket_pool_size 500;
    resolver 8.8.8.8;
    init_worker_by_lua_block {
        require ("px.utils.pxtimer").application()
    }
    set_real_ip_from   0.0.0.0/0;
    real_ip_header     X-Forwarded-For;
--- config

    location  = /vRfnOj4y/init.js {
        resolver 8.8.8.8;
        set_by_lua_block $config {
            pxconfig = require "px.pxconfig"
            pxconfig.cookie_secret = "perimeterx"
            pxconfig.enable_server_calls = false
            pxconfig.send_page_requested_activity = false
            pxconfig.px_debug = true
            pxconfig.px_appId = "PXvRfnOj4y"
            return true
        }

    	access_by_lua_block {
            require("px.pxnginx").application()
        }

    }

--- request
GET /vRfnOj4y/init.js

--- error_log
[PerimeterX - DEBUG] [ PXvRfnOj4y ] - Forwarding request from /vRfnOj4y/init.js to client at client.perimeterx.net/PXvRfnOj4y/main.min.js

=== TEST 2: Forward XHR requests

--- http_config
    lua_package_path "/usr/local/lib/lua/?.lua;/usr/local/openresty/lualib/?.lua;;";
    lua_ssl_trusted_certificate "/etc/ssl/certs/ca-certificates.crt";
    lua_ssl_verify_depth 3;
    lua_socket_pool_size 500;
    resolver 8.8.8.8;
    init_worker_by_lua_block {
        require ("px.utils.pxtimer").application()
    }
    set_real_ip_from   0.0.0.0/0;
    real_ip_header     X-Forwarded-For;
--- config

    location  = /vrfnoj4y/xhr/api/v1/collector {
        resolver 8.8.8.8;
        set_by_lua_block $config {
            pxconfig = require "px.pxconfig"
            pxconfig.cookie_secret = "perimeterx"
            pxconfig.enable_server_calls = false
            pxconfig.send_page_requested_activity = false
            pxconfig.px_debug = true
            pxconfig.px_appId = "pxvrfnoj4y"
            pxconfig.collector_host = string.format('collector-%s.perimeterx.net', pxconfig.px_appId)
            return true
        }

    	access_by_lua_block {
            require("px.pxnginx").application()
        }

    }

--- request
POST /vrfnoj4y/xhr/api/v1/collector HTTP/1.1
content-type: application/x-www-form-urlencoded
cookie: vid=7f803340-9d42-11e7-83a5-8f78028be852; vid=7f803340-9d42-11e7-83a5-8f78028be852\r
Content-Length: 187
payload=W3sidCI6IlBYMiIsImQiOnsiUFg2MyI6Ik1hY0ludGVsIiwiUFg5NiI6Imh0dHA6Ly9zYW1wbGUtbmdpbngucHhjaGsubmV0LyJ9fV0=&appId=PXvRfnOj4y&tag=v2.60&uuid=c18ef200-e96c-11e7-8135-099eab567657&ft=14"

--- error_log
[PerimeterX - DEBUG] [ pxvrfnoj4y ] - Forwarding request from /vrfnoj4y/xhr/api/v1/collector to xhr at collector-pxvrfnoj4y.perimeterx.net/api/v1/collector