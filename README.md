![image](http://media.marketwire.com/attachments/201604/34215_PerimeterX_logo.jpg)

[PerimeterX](http://www.perimeterx.com) NGINX Lua Plugin
=============================================================

Table of Contents
-----------------

-   [Usage](#usage)
  *   [Dependencies](#dependencies)
  *   [Requirements](#requirements)
  *   [Installation](#installation)
  *   [Basic Usage Example](#basic-usage)
-   [Configuration](#configuration)
  *   [Blocking Score](#blocking-score)
  *   [Monitoring mode](#monitoring-mode)
  *   [Enable/Disable Captcha](#captcha-support)
  *   [Enabled Routes](#enabled-routes)
  *   [API Timeout Milliseconds](#api-timeout)
  *   [Send Page Activities](#send-page-activities)
  *   [Debug Mode](#debug-mode)
-   [Whitelisting](#whitelisting)
-   [Contributing](#contributing)

<a name="Usage"></a>

<a name="dependencies"></a> Dependencies
----------------------------------------
- [NGINX >= v1.7](http://nginx.org/) with [Lua NGINX Module](https://github.com/openresty/lua-nginx-module) support (>= v0.9.11) or [Openresty](https://openresty.org/en/)
- [LuaJIT](http://luajit.org/)
- [Lua CJSON](http://www.kyne.com.au/~mark/software/lua-cjson.php)
- [Lua Resty HTTP](https://github.com/pintsized/lua-resty-http)
- [Lua Resty Nettle](https://github.com/bungle/lua-resty-nettle)
- [GNU Nettle >= v3.2](https://www.lysator.liu.se/~nisse/nettle/)


<a name="requirements"></a> Requirements
-----------------------------------------------


### Resolver
Add the directive `resolver A.B.C.D;` to your NGINX configuration file in the http section. This is required so NGINX can resolve the PerimeterX API DNS name.

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

In CentOS/RHEL systems the CA bundle location may be located at `/etc/pki/tls/certs/ca-bundle.crt`

### Lua Timer Initialization
Add the init by lua script.

```
init_worker_by_lua_file "/usr/local/lib/lua/px/utils/pxtimer.lua";
```

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

> Note: IP extraction according to your network setup is important. It is common to have a load balancer/proxy on top of your applications, in this case the PerimeterX module will send an internal IP as the user's. In order to perform processing and detection for server-to-server calls, PerimeterX module need the real user ip.

for the NGINX module to work with the real user IP you need to set the `set_real_ip_from` NGINX directive in your nginx.conf, this will make sure the socket IP used in the nginx is not coming from one of the networks below.

example:
```
  set_real_ip_from 172.0.0.0/8;
  set_real_ip_from 107.178.0.0/16;	
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

#### <a name="blocking-score"></a> Changing the Minimum Score for Blocking

**default:** 70

```
_M.blocking_score = 60
```

#### <a name="monitoring-mode"></a> Monitoring Mode
By default the PerimeterX module will block users crossing the block score threshold you define, meaning, if a user crosses the minimum block score he will get to the block page. The PerimeterX plugin can be activated in monitor mode.

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

<a name="whitelisting"></a> Whitelisting
-----------------------------------------------
Whitelisting (bypassing enforcement) is configured in the file `/usr/local/lib/lua/px/utils/pxfilter.lua`

There are three types of filters that can be configured.

* Full URI
* URI prefix
* IP addresses

<a name="nginxplus"></a> NGINX Plus
-----------------------------------------------
The PerimeterX NGINX module is compatible with NGINX Plus. Users or administrators should install the NGINX Plus Lua dynamic module (LuaJIT).

<a name="contributing"></a> Contributing
----------------------------------------
All contributions are welcome. Send a pull request for review.
