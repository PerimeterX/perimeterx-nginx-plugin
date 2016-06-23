use Test::Nginx::Socket::Lua 'no_plan';

log_level('debug');
run_tests();

__DATA__


=== TEST 1: Sanity Check
Initial test to verify basic settings.

--- http_config
    lua_package_path "/usr/local/lib/lua/?.lua;/usr/local/openresty/lualib/?.lua;;";
    lua_ssl_trusted_certificate "/etc/ssl/certs/ca-certificates.crt";
    lua_ssl_verify_depth 3;
    lua_socket_pool_size 500;
    resolver 8.8.8.8;
    init_worker_by_lua_file "/usr/local/lib/lua/px/utils/pxtimer.lua";
    set_real_ip_from   0.0.0.0/0;
    real_ip_header     X-Forwarded-For;

--- config
    location = /t {
        resolver 8.8.8.8;
        set_by_lua_block $config {
	    pxconfig = require "px.pxconfig"
	    pxconfig.cookie_secret = "perimeterx"
            pxconfig.enable_server_calls = false
            pxconfig.send_page_requested_activity = false
	    pxconfig.px_debug = true
            return true
    }

        access_by_lua_file "/usr/local/lib/lua/px/pxnginx.lua";

        content_by_lua_block {
            ngx.say(ngx.var.remote_addr)
        }
    }

--- request
GET /t

--- more_headers
X-Forwarded-For: 1.2.3.4

--- response_body
1.2.3.4

--- error_code: 200
