use strict;
use Test::Nginx::Socket::Lua 'no_plan';

log_level('debug');
run_tests();

__DATA__


=== TEST 1: Captcha Check
Initial test to verify basic settings.

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
    location = /t {
        resolver 8.8.8.8;
        set_by_lua_block $config {
            pxconfig = require "px.pxconfig"
            pxconfig.cookie_secret = "perimeterx"
            pxconfig.px_debug = true
            pxconfig.block_enabled = true
            pxconfig.captcha_enabled = true
            return true
        }

    	access_by_lua_block {
            require("px.pxnginx").application()
        }

        content_by_lua_block {
            ngx.say(ngx.var.remote_addr)
        }
    }

--- request
GET /t

--- more_headers
X-Forwarded-For: 1.2.3.4
Cookie: _pxCaptcha=cpathcavalue:628a96c0-ebb0-11e6-b1b9-8bb13181c15e:628a96c1-ebb0-11e6-b1b9-8bb13181c15e

--- error_code: 200

--- error_log
PX DEBUG: Processing new CAPTCHA object
PX DEBUG: Sending Captcha API call to eval cookie