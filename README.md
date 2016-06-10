# PX Nginx Plugin

## Requirements
1. Lua CJSON - http://www.kyne.com.au/~mark/software/lua-cjson.php
2. Lua Resty HTTP - https://github.com/pintsized/lua-resty-http
3. Lua Resy Nettle - https://github.com/bungle/lua-resty-nettle (requires libnettle 3.2 or higher)
4. NGINX with ngx_lua support or Openresty
5. LuaJIT

See the directory *vendor* for the dependency sources and installation notes.

## Installation

```
sudo make install
```

The installation location can be changed by setting PREFIX and LUA_LIB_DIR to your specific directory.

## Configuration

### Resolver
Add the directive `resolver A.B.C.D;` to your NGINX configuration file in the http section. This is required so NGINX can resolve the PerimeterX collector DNS name.

### Lua Package Path
Update your lua package path location in the HTTP section of your configuration to reflect where you have installed the modules.

```
lua_package_path "/usr/local/lib/lua/?.lua;;"; 
```

### Lua CA Certificates
To support TLS to the collector you must point Lua to the trusted certificate location (actual location may differ between Linux distributions)

```
lua_ssl_trusted_certificate "/etc/ssl/certs/ca-certificates.crt";
lua_ssl_verify_depth 3;
```

### Lua Timer Initialization
Add the init by lua script.

```
init_worker_by_lua_file "/usr/local/lib/lua/px/utils/pxtimer.lua";
```

### pxconfig.lua 
The following values must be set in pxconfig.lua.

```
_M.px_appId = 'APP_ID'
_M.cookie_encrypted = false
_M.cookie_secret = 'COOKIE_SECRET'
_M.auth_token = 'JWT_AUTH_TOKEN'
```

px_token should be set to a randomly generated string

px_appID should be set to your application ID issued by PerimeterX

cookie_encrypted = true or false based on how you configured the risk cookie in the portal

cookie_secret = the cookie secret for your application from the portal

auth_token = application specific auth token to enable using the risk api for clients who are missing the cookie

### Whitelist 
Whitelisting (bypassing enforcement) is configured in the file utils/pxfilters.lua.

There are three types of filters that can be configured.

* Full URI
* URI prefix
* IP addresses

### Applying the Enforcement to Your Locations


```
location / {
    #----- PerimeterX Module -----#
    access_by_lua_file /usr/local/lib/lua/px/pxnginx.lua;
    #----- PerimeterX Module End -----#
    try files ....;
    }
```

### Sample NGINX Configuration

```
worker_processes  1;
error_log /var/log/nginx/error.log;
events {
    worker_connections 1024;
}

http {
    lua_package_path "/usr/local/lib/lua/?.lua;;";
    init_worker_by_lua_file "/usr/local/lib/lua/px/utils/pxtimer.lua";
    lua_ssl_trusted_certificate "/etc/ssl/certs/ca-certificates.crt";
    lua_ssl_verify_depth 3;
    
    resolver 8.8.8.8;

    server {
        listen 80;

        location / {
            #----- PerimeterX Module Start -----#
            access_by_lua_file /usr/local/lib/lua/px/pxnginx.lua;
            #----- PerimeterX Module End   -----#

            root   /nginx/www;
            index  index.html;
        }
    }
}
```



