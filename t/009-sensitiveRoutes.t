use Test::Nginx::Socket::Lua 'no_plan';

sub bake_cookie {
    use Crypt::KeyDerivation 'pbkdf2';
    use Crypt::Misc 'encode_b64', 'decode_b64';
    use Crypt::Mac::HMAC 'hmac_hex';
    use Crypt::Mode::CBC;

    my ( $ip, $ua, $score, $uuid, $vid, $time ) = @_;

    my $password        = "perimeterx";
    my $salt            = '12345678123456781234567812345678';
    my $iteration_count = 1000;
    my $hash_name       = undef;                              #default is SHA256
    my $len             = 48;

    my $km = pbkdf2( $password, $salt, $iteration_count, $hash_name, $len );
    my $key = substr( $km, 0,  32 );
    my $iv  = substr( $km, 32, 48 );
    my $action = 'a';
    my $m         = Crypt::Mode::CBC->new('AES');
    my $plaintext = '{"u":"' . $uuid. '", "v":"' . $vid . '", "t":' . $time . ', "s":'. $score . ', "a":"' . $action . '"}';
    my $ciphertext = $m->encrypt( $plaintext, $key, $iv );
    my $cookie = encode_b64($salt) . ":" . 1000 . ":" . encode_b64($ciphertext);
    my $hmac      = hmac_hex( 'SHA256', $password, $cookie . $ua );
    $cookie = $hmac . ":" . $cookie;
    return 'Cookie: _px3=' . $cookie;
}

add_block_preprocessor(
    sub {
        my $block  = shift;
        my $time   = ( time() + 360 ) * 1000;
        my $cookie = bake_cookie(
            "1.2.3.4",
'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36',
            '0',
            "57ecdc10-0e97-11e6-80b6-095df820282c",
            "vid",
            $time
        );

        $block->set_value( "more_headers",
            $block->req_headers . "\n" . $cookie );
    }
);

log_level('debug');
run_tests();

__DATA__


=== TEST 1: Call server if match sensitive routes prefix


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
    location = /test {
        resolver 8.8.8.8;
        set_by_lua_block $config {
    	    pxconfig = require "px.pxconfig"
    	    pxconfig.cookie_secret = "perimeterx"
    	    pxconfig.px_debug = true
    	    pxconfig.block_enabled = true
            pxconfig.enable_server_calls  = false
            pxconfig.send_page_requested_activity = false
            pxconfig.sensitive_routes_prefix = {'/t', '/a'}
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
GET /test

--- req_headers
X-Forwarded-For: 1.2.3.4
User-Agent:  Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36

--- response_body
1.2.3.4

--- error_code: 200

--- error_log
[PerimeterX - DEBUG] [ PX_APP_ID ] - Sensitive route match

=== TEST 2: Pass if no match to sensitive routes prefix


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
    location = /test {
        resolver 8.8.8.8;
        set_by_lua_block $config {
    	    pxconfig = require "px.pxconfig"
    	    pxconfig.cookie_secret = "perimeterx"
    	    pxconfig.px_debug = true
    	    pxconfig.block_enabled = true
            pxconfig.enable_server_calls  = false
            pxconfig.send_page_requested_activity = false
            pxconfig.sensitive_routes_prefix = {'/a'}
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
GET /test

--- req_headers
X-Forwarded-For: 1.2.3.4
User-Agent:  Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36

--- response_body
1.2.3.4

--- error_code: 200

--- error_log
[PerimeterX - DEBUG] [ PX_APP_ID ] - Cookie evaluation ended successfully, risk score: 0

=== TEST 3: Call server if match sensitive routes suffix


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
    location = /test/view {
        resolver 8.8.8.8;
        set_by_lua_block $config {
    	    pxconfig = require "px.pxconfig"
    	    pxconfig.cookie_secret = "perimeterx"
    	    pxconfig.px_debug = true
    	    pxconfig.block_enabled = true
            pxconfig.enable_server_calls  = false
            pxconfig.send_page_requested_activity = false
            pxconfig.sensitive_routes_suffix = {'/download', '/view'}
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
GET /test/view

--- req_headers
X-Forwarded-For: 1.2.3.4
User-Agent:  Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36

--- response_body
1.2.3.4

--- error_code: 200

--- error_log
[PerimeterX - DEBUG] [ PX_APP_ID ] - cookie verification passed, risk api triggered by sensitive route

=== TEST 4: Pass if no match to sensitive routes suffix


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
    location = /test/view {
        resolver 8.8.8.8;
        set_by_lua_block $config {
    	    pxconfig = require "px.pxconfig"
    	    pxconfig.cookie_secret = "perimeterx"
    	    pxconfig.px_debug = true
    	    pxconfig.block_enabled = true
            pxconfig.enable_server_calls  = false
            pxconfig.send_page_requested_activity = false
            pxconfig.sensitive_routes_suffix = {'/download'}
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
GET /test/view

--- req_headers
X-Forwarded-For: 1.2.3.4
User-Agent:  Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36

--- response_body
1.2.3.4

--- error_code: 200

--- error_log
[PerimeterX - DEBUG] [ PX_APP_ID ] - Cookie evaluation ended successfully, risk score: 0