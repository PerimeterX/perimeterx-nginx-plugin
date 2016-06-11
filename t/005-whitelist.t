use Test::Nginx::Socket::Lua 'no_plan';

sub bake_cookie {
    use Crypt::KeyDerivation 'pbkdf2';
    use Crypt::Misc 'encode_b64', 'decode_b64';
    use Crypt::Mac::HMAC 'hmac_hex';
    use Crypt::Mode::CBC;

    my ( $ip, $ua, $score, $uuid, $vid, $time ) = @_;
    my $data = $time . '0' . $score . $uuid . $vid . $ip . $ua;

    my $password        = "perimeterx";
    my $salt            = '12345678123456781234567812345678';
    my $iteration_count = 1000;
    my $hash_name       = undef;                              #default is SHA256
    my $len             = 48;

    my $km = pbkdf2( $password, $salt, $iteration_count, $hash_name, $len );
    my $key = substr( $km, 0,  32 );
    my $iv  = substr( $km, 32, 48 );

    my $m         = Crypt::Mode::CBC->new('AES');
    my $hmac      = hmac_hex( 'SHA256', $password, $data );
    my $plaintext = '{"t":'
      . $time
      . ', "s":{"b":'
      . $score
      . ', "a":0}, "u":"'
      . $uuid
      . '", "v":"'
      . $vid
      . '", "h":"'
      . $hmac . '"}';
    my $ciphertext = $m->encrypt( $plaintext, $key, $iv );

    my $cookie = encode_b64($salt) . ":" . 1000 . ":" . encode_b64($ciphertext);
    return 'Cookie: _px=' . $cookie;
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

=== TEST 1: Whitelist - IP

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
	    pxconfig.px_debug = true
	    pxconfig.block_enabled = true
            pxconfig.enable_server_calls  = false
            pxconfig.send_page_requested_activity = false
            px_filters = require "px.utils.pxfilters"
            px_filters.Whitelist['ip_addresses'] = {'1.2.3.4'}
            return true
    }

        access_by_lua_file "/usr/local/lib/lua/px/pxnginx.lua";
        content_by_lua_block {
             ngx.say(ngx.var.remote_addr)
        }
}

--- request
GET /t

--- req_headers
X-Forwarded-For: 1.2.3.4
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36

--- response_body
1.2.3.4

--- error_code: 200

--- error_log
PX DEBUG: Whitelisted: IP address  1.2.3.4

=== TEST 2: Whitelist - URI Full 

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
    location = /t/full/uri {
        resolver 8.8.8.8;
        set_by_lua_block $config {
	    pxconfig = require "px.pxconfig"
	    pxconfig.cookie_secret = "perimeterx"
	    pxconfig.px_debug = true
	    pxconfig.block_enabled = true
            pxconfig.enable_server_calls  = false
            pxconfig.send_page_requested_activity = false
            px_filters = require "px.utils.pxfilters"
            px_filters.Whitelist['ip_addresses'] = {}
            px_filters.Whitelist['uri_full'] = {'/t/full/uri'}
            return true
    }

        access_by_lua_file "/usr/local/lib/lua/px/pxnginx.lua";
        content_by_lua_block {
             ngx.say(ngx.var.remote_addr)
        }
}


--- request
GET /t/full/uri

--- req_headers
X-Forwarded-For: 1.2.3.4
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36

--- response_body
1.2.3.4

--- error_code: 200

--- error_log
PX DEBUG: Whitelisted: uri_full. /t/full/uri

=== TEST 3: Whitelist - URI Prefix

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
    location = /t/prefix/uri {
        resolver 8.8.8.8;
        set_by_lua_block $config {
	    pxconfig = require "px.pxconfig"
	    pxconfig.cookie_secret = "perimeterx"
	    pxconfig.px_debug = true
	    pxconfig.block_enabled = true
            pxconfig.enable_server_calls  = false
            pxconfig.send_page_requested_activity = false
            px_filters = require "px.utils.pxfilters"
            px_filters.Whitelist['ip_addresses'] = {}
            px_filters.Whitelist['uri_full'] = {}
            px_filters.Whitelist['uri_prefixes'] = {'/t/prefix'}
            return true
    }

        access_by_lua_file "/usr/local/lib/lua/px/pxnginx.lua";
        content_by_lua_block {
             ngx.say(ngx.var.remote_addr)
        }
}


--- request
GET /t/prefix/uri

--- req_headers
X-Forwarded-For: 1.2.3.4
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36

--- response_body
1.2.3.4

--- error_code: 200

--- error_log
PX DEBUG: Whitelisted: uri_prefixes. /t/prefix

=== TEST 4: Whitelist - Suffix

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
    location = /t/t.css {
        resolver 8.8.8.8;
        set_by_lua_block $config {
	    pxconfig = require "px.pxconfig"
	    pxconfig.cookie_secret = "perimeterx"
	    pxconfig.px_debug = true
	    pxconfig.block_enabled = true
            pxconfig.enable_server_calls  = false
            pxconfig.send_page_requested_activity = false
            px_filters = require "px.utils.pxfilters"
            px_filters.Whitelist['ip_addresses'] = {}
            px_filters.Whitelist['uri_full'] = {}
            px_filters.Whitelist['uri_prefixes'] = {}
            return true
    }

        access_by_lua_file "/usr/local/lib/lua/px/pxnginx.lua";
        content_by_lua_block {
             ngx.say(ngx.var.remote_addr)
        }
}

--- user_files
>>> t.css 
Hello, world

--- request
GET /t/t.css

--- req_headers
X-Forwarded-For: 1.2.3.4
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36

--- response_body
1.2.3.4

--- error_code: 200

--- error_log
PX DEBUG: Whitelisted: uri_suffix. .css

=== TEST 5: Whitelist - Full UA 

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
    location = /t/t.css {
        resolver 8.8.8.8;
        set_by_lua_block $config {
	    pxconfig = require "px.pxconfig"
	    pxconfig.cookie_secret = "perimeterx"
	    pxconfig.px_debug = true
	    pxconfig.block_enabled = true
            pxconfig.enable_server_calls  = false
            pxconfig.send_page_requested_activity = false
            px_filters = require "px.utils.pxfilters"
            px_filters.Whitelist['ip_addresses'] = {}
            px_filters.Whitelist['uri_full'] = {}
            px_filters.Whitelist['uri_prefixes'] = {}
            px_filters.Whitelist['ua_full'] = {'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36'}
            return true
    }

        access_by_lua_file "/usr/local/lib/lua/px/pxnginx.lua";
        content_by_lua_block {
             ngx.say(ngx.var.remote_addr)
        }
}

--- user_files
>>> t.css 
Hello, world

--- request
GET /t/t.css

--- req_headers
X-Forwarded-For: 1.2.3.4
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36

--- response_body
1.2.3.4

--- error_code: 200

--- error_log
PX DEBUG: Whitelisted: UA strict match Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36

=== TEST 6: Whitelist - UA Partial 

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
    location = /t/t.css {
        resolver 8.8.8.8;
        set_by_lua_block $config {
	    pxconfig = require "px.pxconfig"
	    pxconfig.cookie_secret = "perimeterx"
	    pxconfig.px_debug = true
	    pxconfig.block_enabled = true
            pxconfig.enable_server_calls  = false
            pxconfig.send_page_requested_activity = false
            px_filters = require "px.utils.pxfilters"
            px_filters.Whitelist['ip_addresses'] = {}
            px_filters.Whitelist['uri_full'] = {}
            px_filters.Whitelist['uri_prefixes'] = {}
            px_filters.Whitelist['ua_full'] = {}
            px_filters.Whitelist['ua_sub'] = {'Mozilla/5.0'}
            return true
    }

        access_by_lua_file "/usr/local/lib/lua/px/pxnginx.lua";
        content_by_lua_block {
             ngx.say(ngx.var.remote_addr)
        }
}

--- user_files
>>> t.css 
Hello, world

--- request
GET /t/t.css

--- req_headers
X-Forwarded-For: 1.2.3.4
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36

--- response_body
1.2.3.4

--- error_code: 200

--- error_log
PX DEBUG: Whitelisted: UA partial match Mozilla/5.0
