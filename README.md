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
  *   [Custom Block Page](#customblockpage)
  *   [Multiple App Support](#multipleapps)
-   [Whitelisting](#whitelisting)
-   [Contributing](#contributing)
  *   [Tests](#tests)

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
Add the directive `resolver A.B.C.D;` to your NGINX configuration file in the HTTP section. This is required so NGINX can resolve the PerimeterX API DNS name.

### Lua Package Path
Update your Lua package path location in the HTTP section of your configuration to reflect where you have installed the modules.

```
lua_package_path "/usr/local/lib/lua/?.lua;;";
```

### Lua CA Certificates
To support TLS to the collector, you must point Lua to the trusted certificate location (actual location may differ between Linux distributions).

```
lua_ssl_trusted_certificate "/etc/ssl/certs/ca-certificates.crt";
lua_ssl_verify_depth 3;
```

In CentOS/RHEL systems, the CA bundle location may be located at `/etc/pki/tls/certs/ca-bundle.crt`.

### Lua Timer Initialization
Add the init by lua script.

```
init_worker_by_lua_block {
    require ("px.utils.pxtimer").application()
}
```

<a name="installation"></a> Installation
----------------------------------------

Installation can be done using [luarocks](https://luarocks.org/).

```sh
$ luarocks install perimeterx-nginx-plugin
```

It can also be accomplished by downoading the sources for this repository and running `sudo make install`.

### <a name="basic-usage"></a> Basic Usage Example

To apply PerimeterX enforcement, add the following line to your location block:

```
access_by_lua_block { 
	require("px.pxnginx").application()
}
```

Below is a complete example of nginx.conf containing the required directives and with enforcement applied to the location block..

#### nginx.conf
```lua
worker_processes  1;
error_log /var/log/nginx/error.log;
events {
    worker_connections 1024;
}

http {
    lua_package_path "/usr/local/lib/lua/?.lua;;";

    # -- initializing the perimeterx module -- #
	init_worker_by_lua_block {
        require ("px.utils.pxtimer").application()
    }

    lua_ssl_trusted_certificate "/etc/ssl/certs/ca-certificates.crt";
    lua_ssl_verify_depth 3;

    resolver 8.8.8.8;

    server {
        listen 80;

        location / {
            #----- PerimeterX protect location -----#
			access_by_lua_block { 
				require("px.pxnginx").application()
			}
            #----- PerimeterX Module End  -----#

            root   /nginx/www;
            index  index.html;
        }
    }
}
```

### Extracting the real IP address from a request

> Note: IP extraction, according to your network setup, is very important. It is common to have a load balancer/proxy on top of your applications, in which case the PerimeterX module will send the system's internal IP as the user's. In order to properly perform processing and detection on server-to-server calls, the PerimeterX module requires the user's real IP address.

For the NGINX module to work with the real user's IP, you need to set the `set_real_ip_from` NGINX directive in your nginx.conf. This will make sure the socket IP used in NGINX is not coming from one of the network levels below it.

example:
```
  set_real_ip_from 172.0.0.0/8;
  set_real_ip_from 107.178.0.0/16;	
 ```

### <a name="configuration"></a> Configuration Options

#### Configuring Required Parameters

Configuration options are set in the file `/usr/local/lib/lua/px/pxconfig.lua`.

#### Required parameters:

- px_appId
- cookie_secret
- auth_token

#### <a name="blocking-score"></a> Changing the Minimum Score for Blocking

**Default blocking value:** 70

```
_M.blocking_score = 60
```

#### <a name="monitoring-mode"></a> Monitoring Mode
By default, the PerimeterX module will block users crossing the block score threshold that you define. This means that if a user crosses the minimum block score he will receive the block page. The PerimeterX plugin can also be activated in monitor only mode.
Setting the block_enalbed flag to *false* will prevent the block page from being displayed to the user, but the data will still be available in the PerimeterX Portal.

```
_M.block_enabled = false
```
Disabling blocking means users crossing the blocking threshold will not be activly blocked, but you will still be able to consume their score through a custom request header `X-PX-SCORE`.

#### <a name="captcha-support"></a>Enable/Disable CAPTCHA on the block page

By enabling CAPTCHA support, a CAPTCHA will be served as part of the block page, giving real users the ability to identify as a human. By solving the CAPTCHA, the user's score is then cleaned up and the user is allowed to continue.

**Default: true**

```
_M.captcha_enabled = false
```


#### <a name="enabled-routes"></a> Enabled Routes

The enabled routes variable allow you to implicitly define a set of routes which the plugin will be active on. Supplying an empty list will set all application routes as active.

**Default: Empty list (all routes)**

```php
_M.enabled_routes = {'/blockhere'}
```


#### <a name="api-timeout"></a>API Timeout Milliseconds
> Note: Controls the timeouts for PerimeterX requests. The API is called when a Risk Cookie does not exist, or is expired or invalid.

API Timeout in milliseconds (float) to wait for the PerimeterX server API response.

**Default:** 1000

```
_M.s2s_timeout = 250
```

#### <a name="send-page-activities"></a> Send Page Activities

A boolean flag to determine whether or not to send activities and metrics to PerimeterX, on each page request. Disabling this feature will prevent PerimeterX from receiving data populating the PerimeterX portal, containing valuable information such as the amount of requests blocked and other API usage statistics.

**Default:** true

```php
_M.send_page_requested_activity = false
```

#### <a name="debug-mode"></a> Debug Mode

Enables debug logging mode.

**Default:** false

```
_M.px_debug = true
```

#### <a name="customblockpage"></a> Custom Block Page

Users can customize the blocking page to meet their branding and message requirements by specifying the URL to a blocking page HTML file. The page can also implement reCaptcha. See <docs location> for more examples of a customized reCaptcha page.


**default:** nil

```
_M.custom_block_url = nil
```

> Note: This URI is whitelisted automatically under `_M.Whitelist['uri_full'] ` to avoid infinite redirects.

##### Blocked user example: 

If a user is blocked when browsing to `http://www.mysite.com/coolpage`, and the server configuration is: 

```lua
_M.custom_block_url /block.html
```

the redirect URL will be:

```
http://www.mysite.com/block.html&url=/coolpage&uuid=uuid=e8e6efb0-8a59-11e6-815c-3bdad80c1d39&vid=08320300-6516-11e6-9308-b9c827550d47
```

###### Custom blockpage requirements:

When captcha is enabled, the block page **must** include the following:

* Inside the `<head>` section:

```html
<script src="https://www.google.com/recaptcha/api.js"></script>
<script>
function handleCaptcha(response) {
    var vid = getQueryString("vid"); // getQueryString is implemented below
    var uuid = getQueryString("uuid");
    var name = '_pxCaptcha';
    var expiryUtc = new Date(Date.now() + 1000 * 10).toUTCString();
    var cookieParts = [name, '=', response + ':' + vid + ':' + uuid, '; expires=', expiryUtc, '; path=/'];
    document.cookie = cookieParts.join('');
    var originalURL = getQueryString("url");
    var originalHost = window.location.host;
    window.location.href = window.location.protocol + "//" +  originalHost + originalURL;
}

// http://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript
function getQueryString(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
            results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, " "));
}
</script>
```
* Inside the `<body>` section:

```
<div class="g-recaptcha" data-sitekey="6Lcj-R8TAAAAABs3FrRPuQhLMbp5QrHsHufzLf7b" data-callback="handleCaptcha" data-theme="dark"></div>
```

* [PerimeterX Javascript snippet](https://console.perimeterx.com/#/app/applicationsmgmt).

#### Configuration example:
 
```lua
_M.custom_block_url /block.html
```


#### Block page implementation full example: 

```html
<html>
    <head>
        <script src="https://www.google.com/recaptcha/api.js"></script>
        <script>
        function handleCaptcha(response) {
            var vid = getQueryString("vid");
            var uuid = getQueryString("uuid");
            var name = '_pxCaptcha';
            var expiryUtc = new Date(Date.now() + 1000 * 10).toUTCString();
            var cookieParts = [name, '=', response + ':' + vid + ':' + uuid, '; expires=', expiryUtc, '; path=/'];
            document.cookie = cookieParts.join('');
            // after getting resopnse we want to reaload the original page requested
            var originalURL = getQueryString("url");
            var originalHost = window.location.host;
            window.location.href = window.location.protocol + "//" +  originalHost + originalURL;
        }
       
       // http://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript
		function getQueryString(name, url) {
		    if (!url) url = window.location.href;
		    name = name.replace(/[\[\]]/g, "\\$&");
		    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
		        results = regex.exec(url);
		    if (!results) return null;
		    if (!results[2]) return '';
		    return decodeURIComponent(results[2].replace(/\+/g, " "));
		}

        </script>
    </head>
    <body>
        <h1>You are Blocked</h1>
        <p>Try and solve the captcha</p> 
        <div class="g-recaptcha" data-sitekey="6Lcj-R8TAAAAABs3FrRPuQhLMbp5QrHsHufzLf7b" data-callback="handleCaptcha" data-theme="dark"></div>
    </body>
<html>
```

#### <a name="multipleapps"></a> Multiple App Support
The PerimeterX Enforcer allows for multiple configurations for different apps.

If your PerimeterX account contains several Applications (as defined via the portal), follow these steps to create different configurations for each Application.

>Note: The application initialises a timed worker. The worker must be initialised using any one of the applications in your account. Be sure to pass the correct configuration file name to the `require ("px.utils.pxtimer").application("AppName"|empty)` block in the server initialization.

- First, open the `nginx.conf` file, and find the following line : `require("px.pxnginx").application()` inside your location block.
- Pass the desired application name into the `application()` function, as such : `require("px.pxnginx").application("mySpecialApp")`
- Then, find your `pxconfig.lua` file, and make a copy of it. name that copy using the following pattern : `pxconfig-<AppName>.lua` (e.g. `pxconfig-mySpecialApp.lua`) - The <AppName> placeholder must be replaced by the exact name provided to the application function in the previous section.
- Change the configuration inside the newly created file, as per your app's needs. (Save it. *duh*) 
- Make sure to save the file in the same location (e.g. `/usr/local/lib/lua/px/<yourFile>`)
- Thats it, in every `location` block of your app - make sure to place the code mentioned on stage 2 with the correct AppName.


<a name="whitelisting"></a> Whitelisting
-----------------------------------------------
Whitelisting (bypassing enforcement) is configured in the file `pxconfig.lua`

There are several different types of filters that can be configured.

```javascript
whitelist = {
	uri_full = { _M.custom_block_url },
	uri_prefixes = {},
	uri_suffixes = {'.css', '.bmp', '.tif', '.ttf', '.docx', '.woff2', '.js', '.pict', '.tiff', '.eot', '.xlsx', '.jpg', '.csv', '.eps', '.woff', '.xls', '.jpeg', '.doc', '.ejs', '.otf', '.pptx', '.gif', '.pdf', '.swf', '.svg', '.ps', '.ico', '.pls', '.midi', '.svgz', '.class', '.png', '.ppt', '.mid', 'webp', '.jar'},
	ip_addresses = {},
	ua_full = {},
	ua_sub = {}
}
```

- **uri_full** : for value `{'/api_server_full'}` - will filter requests to `/api_server_full?data=1` but not to `/api_server?data=1`
- **uri_prefixes** : for value `{'/api_server'}` - will filter requests to `/api_server_full?data=1` but not to `/full_api_server?data=1` 
- **uri_suffixes** : for value `{'.css'}` - will filter requests to `/style.css` but not to `/style.js`
- **ip_addresses** : for value `{'192.168.99.1'}` - will filter requests coming from any of the listed ips.
- **ua_full** : for value `{'Mozilla/5.0 (compatible; pingbot/2.0;  http://www.pingdom.com/)'}` - will filter all requests matching this exact UA. 
- **ua_sub** : for value `{'GoogleCloudMonitoring'}` - will filter requests containing the provided string in their UA.

<a name="nginxplus"></a> NGINX Plus
-----------------------------------------------
The PerimeterX NGINX module is compatible with NGINX Plus. Users or administrators should install the NGINX Plus Lua dynamic module (LuaJIT).

<a name="contributing"></a> Contributing
----------------------------------------
The following steps are welcome when contributing to our project.
###Fork/Clone
First and foremost, [Create a fork](https://guides.github.com/activities/forking/) of the repository, and clone it locally.
Create a branch on your fork, preferably using a self descriptive branch name.

###Code/Run
Code your way out of your mess, and help improve our project by implementing missing features, adding capabilites or fixing bugs.

To run the code, follow the steps in the [installation guide](#installation). Grab the keys from the PerimeterX portal, and try refreshing your page several times continously. If no default behaviours have been overriden, you should see the PerimeterX block page. Solve the CAPTCHA to clean yourself and start fresh again.

Feel free to check out the [Example App](https://nginx-sample-app.perimeterx.com), to get familiar with the project.

###<a name="tests"></a>Test
> Tests for this project are written using the [`Test::Nginx`](https://github.com/openresty/test-nginx) testing framework.

**Dont forget to test**. The project relies heavily on tests, thus ensuring each user has the same experience, and no new features break the code.
Before you create any pull request, make sure your project has passed all tests. If any new features require it, write your own.

To run the tests, first build the docker container. Then, run the tests using the following command : `make docker-test`.

###Pull Request
After you have completed the process, create a pull request to the Upstream repository. Please provide a complete and thorough description explaining the changes. Remember, this code has to be read by our maintainers, so keep it simple, smart and accurate.

###Thanks
After all, you are helping us by contributing to this project, and we want to thank you for it.
We highly appreciate your time invested in contributing to our project, and are glad to have people like you - kind helpers.
