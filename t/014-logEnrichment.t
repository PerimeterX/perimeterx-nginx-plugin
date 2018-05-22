use Test::Nginx::Socket::Lua 'no_plan';

sub bake_cookie {
    use Crypt::KeyDerivation 'pbkdf2';
    use Crypt::Misc 'encode_b64', 'decode_b64';
    use Crypt::Mac::HMAC 'hmac_hex';
    use Crypt::Mode::CBC;

    my ( $ip, $ua, $score, $uuid, $vid, $time ) = @_;

    $vid             = "53d7aa0a-f08c-11e7-8c1d-9a214cf093ae";
    $uuid            = "4fd730c4-f08c-11e7-8c3f-9a214cf093ae";
    my $password        = "perimeterx";
    my $salt            = '12345678123456781234567812345678';
    my $iteration_count = 1000; 
    my $hash_name       = "SHA256";                              #default is SHA256
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
            '100',
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


=== TEST 1: Test Score Header
Set the NGX $pxscore variable

--- http_config
    map score $pxscore {
        default 'nil';
    }
    
    log_format enriched '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" perimeterx_score "$pxscore';

    access_log /var/log/nginx/access_log enriched;

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
    	    pxconfig.block_enabled = false
    	    pxconfig.send_page_requested_activity = false
            pxconfig.enable_server_calls  = false
            return true
        }

    	access_by_lua_block {
	    require("px.pxnginx").application(require "px.pxconfig")
	}

        content_by_lua_block {
             ngx.say(ngx.var.pxscore)
        }
}


--- request
GET /t

--- req_headers
X-Forwarded-For: 1.2.3.4
User-Agent:  Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36

--- response_body
100

=== TEST 2: Test uuid
Set the NGX $pxuuid variable

--- http_config
    map uuid $pxuuid  { default 'none'; }

    log_format enriched '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" perimeterx_score "$pxuuid';

    access_log /var/log/nginx/access_log enriched;

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
    	    pxconfig.block_enabled = false
    	    pxconfig.send_page_requested_activity = false
            pxconfig.enable_server_calls  = false
            return true
        }

    	access_by_lua_block {
	    require("px.pxnginx").application(require "px.pxconfig")
	}

        content_by_lua_block {
             ngx.say(ngx.var.pxuuid)
        }
}


--- request
GET /t

--- req_headers
X-Forwarded-For: 1.2.3.4
User-Agent:  Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36

--- response_body_like
4fd730c4-f08c-11e7-8c3f-9a214cf093ae

=== TEST 3: Test vid
Set the NGX $pxuuid variable

--- http_config
    map vid $pxvid  { default 'none'; }

    log_format enriched '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" perimeterx_score "$pxvid';

    access_log /var/log/nginx/access_log enriched;

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
    	    pxconfig.block_enabled = false
    	    pxconfig.send_page_requested_activity = false
            pxconfig.enable_server_calls  = false
            return true
        }

    	access_by_lua_block {
	    require("px.pxnginx").application(require "px.pxconfig")
	}

        content_by_lua_block {
             ngx.say(ngx.var.pxvid)
        }
}


--- request
GET /t

--- req_headers
X-Forwarded-For: 1.2.3.4
User-Agent:  Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36

--- response_body_like
53d7aa0a-f08c-11e7-8c1d-9a214cf093ae

=== TEST 4: Test vid uuid
Set the NGX $pxuuid variable

--- http_config
    map uuid $pxuuid  { default 'none'; }

    log_format enriched '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" perimeterx_score "$pxuuid';

    access_log /var/log/nginx/access_log enriched;

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
    	    pxconfig.block_enabled = false
    	    pxconfig.send_page_requested_activity = false
            pxconfig.enable_server_calls  = false
            return true
        }

    	access_by_lua_block {
	    require("px.pxnginx").application(require "px.pxconfig")
	}

        content_by_lua_block {
             ngx.say(ngx.var.pxuuid)
        }
}


--- request
GET /t

--- req_headers
X-Forwarded-For: 1.2.3.4
User-Agent:  Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36

--- response_body_like
4fd730c4-f08c-11e7-8c3f-9a214cf093ae

=== TEST 5: Test pxblock
Set the NGX pxblock variable

--- http_config
    map block $pxblock  { default 'none'; }

    log_format enriched '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" perimeterx_score "$pxblock';

    access_log /var/log/nginx/access_log enriched;

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
    	    pxconfig.block_enabled = false
    	    pxconfig.send_page_requested_activity = false
            pxconfig.enable_server_calls  = false
            return true
        }

    	access_by_lua_block {
	    require("px.pxnginx").application(require "px.pxconfig")
	}

        content_by_lua_block {
             ngx.say(ngx.var.pxblock)
        }
}


--- request
GET /t

--- req_headers
X-Forwarded-For: 1.2.3.4
User-Agent:  Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36

--- response_body_like
cookie_high_score

=== TEST 6: Test pxpass
Set the NGX pxblock variable

--- http_config
    map pass $pxpass  { default 'none'; }

    log_format enriched '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" perimeterx_score "$pxpass';

    access_log /var/log/nginx/access_log enriched;

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
    	    pxconfig.block_enabled = false
    	    pxconfig.blocking_score = 101
            pxconfig.enable_server_calls  = false
            return true
        }

    	access_by_lua_block {
	    require("px.pxnginx").application(require "px.pxconfig")
	}

        content_by_lua_block {
             ngx.say(ngx.var.pxpass)
        }
}


--- request
GET /t

--- req_headers
X-Forwarded-For: 1.2.3.4
User-Agent:  Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36

--- response_body_like
cookie
