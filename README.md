# PX Nginx Plugin
For futher information about the design and implemenation follow [the wiki page](https://perimeterx.atlassian.net/wiki/display/PD/Nginx+Plugin).

## Development
1. Required - Local docker environment
2. Follow:
	
		$ git clone https://github.com/PerimeterX/pxNginxPlugin && cd pxNginxPlugin
		$ bash deploy_nginx.sh

The deploy script will launch a docker container with nginx instace compile with lua-nginx-module and the plugin sources 

## Requirements
1. Lua CJSON - http://www.kyne.com.au/~mark/software/lua-cjson.php
2. Lua Resty HTTP - https://github.com/pintsized/lua-resty-http
3. NGINX with ngx_lua support or Openresty

## Installation
```
sudo make install
```
The installation location can be changed by setting PREFIX and LUA_LIB_DIR to your specific directory.
## Configuration

### Resolver
Add the directive `resolver A.B.C.D;` to your NGINX configuration file.

### Lua Package Path
Update your lua package path location in the HTTP section of your configuration to reflect where you have installed the modules.
```
lua_package_path "/usr/local/lib/lua/?.lua;;"; 
```

### Lua CA Certificates
To support TLS to the collector you must point Lua to the trusted certificate location.
```
lua_ssl_trusted_certificate "/etc/ssl/certs/ca-certificates.crt";
lua_ssl_verify_depth 3;
```

### PX Configuration
You must set the following values in pxnginx.lua.
```
local px_token = 'my_temporary_token';
local px_appId = 'PXAPPCODE';
```
px_token should be set to a randomly generated string

px_appID should be set to your application ID issued by PerimeterX 

### Nginx Configuration

```
location / {
            #----- PerimeterX Module -----#
            set_by_lua_file $pxchallenge /usr/local/lib/lua/px/pxnginx.lua;
            
            if ($pxchallenge) {
               content_by_lua_file  /usr/local/lib/lua/px/pxchallenge.lua;
            }
            #----- PerimeterX Module End -----#
        }
```
