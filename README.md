![image](https://843a2be0f3083c485676508ff87beaf088a889c0-www.googledrive.com/host/0B_r_WoIa581oY01QMWNVUElyM2M)

[PerimeterX](http://www.perimeterx.com) NGINX Lua Plugin
=============================================================

Table of Contents
-----------------

-   [Usage](#usage)
  *   [Dependencies](#dependencies)
  *   [Installation](#installation)
  *   [Basic Usage Example](#basic-usage)
-   [Configuration](#configuration)
  *   [Blocking Score](#blocking-score)
  *   [Custom Block Action](#custom-block)
  *   [Enable/Disable Captcha](#captcha-support)
  *   [Enabled Routes](#enabled-routes)
  *   [API Timeout Milliseconds](#api-timeout)
  *   [Send Page Activities](#send-page-activities)
  *   [Debug Mode](#debug-mode)
-   [Whitelisting](#whitelisting)
-   [Common Requirements](#commonr)
-   [Contributing](#contributing)
  *   [Tests](#tests)

<a name="Usage"></a>

<a name="dependencies"></a> Dependencies
----------------------------------------
- NGINX with ngx_lua support or Openresty
- LuaJIT
- [Lua CJSON](http://www.kyne.com.au/~mark/software/lua-cjson.php)
- [Lua Resty HTTP](https://github.com/pintsized/lua-resty-http)
- [Lua Resy Nettle](https://github.com/bungle/lua-resty-nettle)


<a name="installation"></a> Installation
----------------------------------------

Installation can be done using [luarocks](https://luarocks.org/)

```sh
$ luarocks install perimeterx-nginx-plugin
```

Or by downoading the sources for this repository and run `sudo make install`

### <a name="basic-usage"></a> Basic Usage Example

#### nginx.conf
```
worker_processes  1;
error_log /var/log/nginx/error.log;
events {
    worker_connections 1024;
}

http {
    lua_package_path "/usr/local/lib/lua/?.lua;;";
    
    # -- initializing the perimeterx module -- #
    init_worker_by_lua_file "/usr/local/lib/lua/px/utils/pxtimer.lua";
    
    lua_ssl_trusted_certificate "/etc/ssl/certs/ca-certificates.crt";
    lua_ssl_verify_depth 3;
    
    resolver 8.8.8.8;

    server {
        listen 80;

        location / {
            #----- PerimeterX protect location -----#
            access_by_lua_file /usr/local/lib/lua/px/pxnginx.lua;
            #----- PerimeterX Module End  -----#

            root   /nginx/www;
            index  index.html;
        }
    }
}
```

And modifying required configurations on `/usr/local/lib/lua/px/pxconfig.lua`:

```
_M.px_appId = 'APP_ID'
_M.cookie_secret = 'COOKIE_SECRET'
_M.auth_token = 'JWT_AUTH_TOKEN'

```

### <a name="configuration"></a> Configuration Options

#### Configuring Required Parameters

Configuration options are set on `/usr/local/lib/lua/px/pxconfig.lua`:

#### Required parameters:

- px_appId
- cookie_secret
- auth_token

##### <a name="blocking-score"></a> Changing the Minimum Score for Blocking

**default:** 70

```
_M.blocking_score = 60
```

#### <a name="custom-block"></a> Custom Blocking Actions
By default the perimeterx module will block users crossing the block score you define, meaning, if a user cross the minimum block score he will get to the block page. the perimeterx plugin can be activated in monitor mode.

```
_M.block_enabled = false
```

This way users crossing the blocking score will not be activly blocked, but you will be able to consume their score from a request header `X-PX-SCORE`.

#### <a name="captcha-support"></a>Enable/disable captcha in the block page

By enabling captcha support, a captcha will be served as part of the block page giving real users the ability to answer, get score clean up and passed to the requested page.

**default: true**

```
_M.captcha_enabled = false
```


#### <a name="enabled-routes"></a> Enabled Routes

Enabled routes is a list of routes you can implicitly define where the plugin will be active on. empty list will active plugin on all routes.

**default: all routes**

```php
_M.enabled_routes = {'/blockhere'}
```


#### <a name="api-timeout"></a>API Timeout Milliseconds

Timeout in milliseconds (float) to wait for the PerimeterX server API response.
The API is called when the risk cookie does not exist, or is expired or
invalid.

**default:** 1000

```
_M.s2s_timeout = 250
```

#### <a name="send-page-activities"></a> Send Page Activities

Boolean flag to enable or disable sending activities and metrics to
PerimeterX on each page request. Enabling this feature will provide data
that populates the PerimeterX portal with valuable information such as
amount requests blocked and API usage statistics.

**default:** false

```php
_M.send_page_requested_activity = false
```

#### <a name="debug-mode"></a> Debug Mode

Enables debug logging

**default:** false

```
_M.px_debug = true
```

<a name="whitelist"></a> Whitelisting
-----------------------------------------------
Whitelisting (bypassing enforcement) is configured in the file `/usr/local/lib/lua/px/utils/pxfilter.lua`

There are three types of filters that can be configured.

* Full URI
* URI prefix
* IP addresses


<a name="commonr"></a> Common Requirements
-----------------------------------------------


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


<a name="contributing"></a> Contributing
----------------------------------------

