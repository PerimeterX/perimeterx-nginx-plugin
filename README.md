![image](https://s.perimeterx.net/logo.png)

[PerimeterX](http://www.perimeterx.com) NGINX Lua Plugin
=============================================================

Table of Contents
-----------------

-   [Getting Started](#gettingstarted)
  *   [Dependencies](#dependencies)
  *   [Requirements](#requirements)
  *   [Installation](#installation)
  *   [Installing on Amazon Linux](#awsinstall)
  *   [Basic Usage Example](#basic-usage)
-   [Configuration](#configuration)
  *   [Blocking Score](#blocking-score)
  *   [Monitoring mode](#monitoring-mode)
  *   [Enable/Disable Captcha](#captcha-support)
  *   [Select Captcha Provider](#captcha-provider)
  *   [Enabled Routes](#enabled-routes)
  *   [Sensitive Routes](#sensitive-routes)
  *   [API Timeout](#api-timeout)
  *   [Send Page Activities](#send-page-activities)
  *   [Debug Mode](#debug-mode)
  *   [Custom Block Page](#customblockpage)  
  *   [Multiple App Support](#multipleapps)
  *   [Additional Activity Handler](#add-activity-handler)
  *   [Whitelisting](#whitelisting)
-   [Appendix](#appendix)
  *   [NGINX Plus](#nginxplus)
  *   [NGINX Dynamic Modules](#dynamicmodules)
  *   [Contributing](#contributing)

<a name="gettingstarted"></a> Getting Started
----------------------------------------

<a name="dependencies"></a> Dependencies
----------------------------------------
- [NGINX 1.7 up to 1.11.6](http://nginx.org/) with [Lua NGINX Module](https://github.com/openresty/lua-nginx-module) support (>= v0.9.11) or [Openresty](https://openresty.org/en/)
- [LuaJIT](http://luajit.org/)
- [Lua CJSON](http://www.kyne.com.au/~mark/software/lua-cjson.php)
- [Lua Resty HTTP](https://github.com/pintsized/lua-resty-http)
- [Lua Resty Nettle](https://github.com/bungle/lua-resty-nettle)
- [lustache](https://github.com/Olivine-Labs/lustache)
- [GNU Nettle >= v3.2](https://www.lysator.liu.se/~nisse/nettle/)

To install package dependecies on Ubuntu run:

`sudo apt-get update && sudo apt-get install lua-cjson libnettle6 nettle-dev luarocks luajit libluajit-5.1-dev ca-certificates`

All Lua dependecies are automatically fulfilled with Luarocks.

<a name="installation"></a> Installation
----------------------------------------

Installation can be done using [luarocks](https://luarocks.org/).

```sh
$ luarocks install perimeterx-nginx-plugin
```

Manual installation can accomplished by downoading the sources for this repository and running `sudo make install`.  

<a name="awsinstall"></a> Additional steps for installing on Amazon Linux
----------------------------------------  
### For Nginx+: 
Install the lua modules provided by the Nginx team via yum as shown below as well as the CA certificates bundle which will be required when you configure Nginx.

```
yum -y install nginx-plus-module-lua ca-certificates.noarch
```

Download and compile nettle. 
>> Side note: Use the version neccessary for your environment. 

```
yum -y install m4 # prerequisite for nettle
cd /tmp/
wget https://ftp.gnu.org/gnu/nettle/nettle-3.3.tar.gz
tar -xzf nettle-3.3.tar.gz
cd nettle-3.3
./configure
make clean && make install
cd /usr/lib64 && ln -s /usr/local/lib64/libnettle.so . 
```

Make sure to change the path shown below in the "Lua CA Certificates" section as Amazon Linux stores the CA required in a different location than shown.

If running Amazon Linux this is the trusted certificate path please use:  

```
lua_ssl_trusted_certificate "/etc/pki/tls/certs/ca-bundle.crt";
```

<a name="requirements"></a> NGINX Configuration File Requirements
-----------------------------------------------


### Resolver
Add the directive `resolver A.B.C.D;` in the HTTP section of your configuration. This is required so NGINX can resolve the PerimeterX API DNS name. `A.B.C.D` is the IP address of your DNS resolver.

### Lua Package Path
Update your Lua package path location in the HTTP section of your configuration to reflect where you have installed the modules.

```
lua_package_path "/usr/local/lib/lua/?.lua;;";
```

### Lua CA Certificates
To support TLS to PerimeterX servers, you must point Lua to the trusted certificate location (actual location may differ between Linux distributions).

```
lua_ssl_trusted_certificate "/etc/ssl/certs/ca-certificates.crt";
lua_ssl_verify_depth 3;
```

In CentOS/RHEL systems, the CA bundle location may be located at `/etc/pki/tls/certs/ca-bundle.crt`.

### Lua Timer Initialization
Add the init by lua script. This is used by PerimeterX to hold and send metrics on regular intervals.

```
init_worker_by_lua_block {
    require ("px.utils.pxtimer").application()
}
```

### <a name="basic-usage"></a> Basic Usage Example

Ensure that you followed the NGINX Configuration Requirements section before proceeding.

To apply PerimeterX enforcement, add the following line to your location block:

```
access_by_lua_block { 
	require("px.pxnginx").application()
}
```

Below is a complete example of nginx.conf containing the required directives and with enforcement applied to the location block.

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

> Note: It is important that the real connection IP is properly extracted when your NGINX server sits behind a load balancer or CDN. The PerimeterX module requires the user's real IP address.

For the PerimeterX NGINX module to see the real user's IP address, you need to have the `set_real_ip_from` and `real_ip_header` NGINX directives in your nginx.conf. This will make sure the connecting IP is properly derived from a trusted source.

Example:

```
  set_real_ip_from 172.0.0.0/8;
  set_real_ip_from 107.178.0.0/16; 
  real_ip_header X-Forwarded-For;
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

#### <a name="captcha-provider"></a>Select CAPTCHA Provider

The CAPTCHA part of the block page can use one of the following:
* [reCAPTCHA](https://www.google.com/recaptcha)
* [FunCaptcha](https://www.funcaptcha.com/)

**Default: 'reCaptcha'**
```lua
_M.captcha_provider = "funCaptcha"
```

#### <a name="enabled-routes"></a> Enabled Routes

The enabled routes variable allows you to implicitly define a set of routes which the plugin will be active on. Supplying an empty list will set all application routes as active.

**Default: Empty list (all routes)**

```lua
_M.enabled_routes = {'/blockhere'}
```

#### <a name="sensitive-routes"></a> Sensitive Routes

Lists of route prefixes and suffixes. The PerimeterX module will always match the request URI with these lists, and if a match is found will create a server-to-server call, even if the cookie is valid and its score is low.

**Default: Empty list**

```lua
_M.sensitive_routes_prefix = {'/login', '/user/profile'}
_M.sensitive_routes_suffix = {'/download'}
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

Customizing block page can be done by 2 methods:
##### Modifying default block pages
PerimeterX default block page can be modified by injecting custom css, javascript and logo to page

**default values:** nil

Example:

```
_M.custom_logo = "http://www.example.com/logo.png"
_M.css_ref = "http://www.example.com/style.css"
_M.js_ref = "http://www.example.com/script.js"
```
##### Redirect to a custom block page url
Users can customize the blocking page to meet their branding and message requirements by specifying the URL to a blocking page HTML file. The page can also implement reCaptcha. See <docs location> for more examples of a customized reCaptcha page.

**default:** nil

```
_M.custom_block_url = nil
```

> Note: This URI is whitelisted automatically under `_M.Whitelist['uri_full'] ` to avoid infinite redirects.

##### Blocked user example: 

If a user is blocked when browsing to `http://www.mysite.com/coolpage`, and the server configuration is: 

```lua
_M.custom_block_url = '/block.html'
```

#### <a name="redirect_on_custom_url"></a> Redirect on Custom URL
The `_M.redirect_on_custom_url` flag provides 2 options for redirecting users to a block page.

**default:** false

```lua
_M.redirect_on_custom_url = false
```

By default, when a user crosses the blocking threshold and blocking is enabled, the user will be redirected to the block page defined by the `_M.custom_block_url` variable, responding with a 307 (Temporary Redirect) HTTP Response Code.


Setting the flag to flase will *consume* the page and serve it under the current URL, responding with a 403 (Unauthorized) HTTP Response Code.

>_Setting the flag to **false** does not require the block page to include any of the coming examples, as they are injected into the blocking page via the PerimeterX Nginx Enforcer._

Setting the flag to **true** (enabling redirects) will result with the following URL upon blocking:

```
http://www.example.com/block.html?url=L3NvbWVwYWdlP2ZvbyUzRGJhcg==&uuid=e8e6efb0-8a59-11e6-815c-3bdad80c1d39&vid=08320300-6516-11e6-9308-b9c827550d47
```
>Note: the **url** variable is comprised of URL Encoded query parameters (of the originating request) and then both the original path and variables are Base64 Encoded (to avoid collisions with block page query params). 

 

###### Custom blockpage requirements:

When captcha is enabled, and `_M.redirect_on_custom_url` is set to **true**, the block page **must** include the following:

* The `<head>` section **must** include:

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

// for reference : http://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript

function getQueryString(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
            results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    results[2] = decodeURIComponent(results[2].replace(/\+/g, " "));
    if(name == "url") {
      results[2] = atob(results[2]); //Not supported on IE Browsers
    }
    return results[2];
}
</script>
```
* The `<body>` section **must** include:

```
<div class="g-recaptcha" data-sitekey="6Lcj-R8TAAAAABs3FrRPuQhLMbp5QrHsHufzLf7b" data-callback="handleCaptcha" data-theme="dark"></div>
```

* And the [PerimeterX Javascript snippet](https://console.perimeterx.com/#/app/applicationsmgmt) (availabe on the PerimeterX Portal via this link) must be pasted in.

#### Configuration example:
 
```lua
_M.custom_block_url = '/block.html'
_M.redirect_on_custom_url = true
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
        if(name == "url") {
          results[2] = atob(results[2]); //Not supported on IE Browsers
        }
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


#### <a name="add-activity-handler"></a> Additional Activity Handler
Adding an additional activity handler is done by setting '_M.additional_activity_handler' with a user defined function on the 'pxconfig.lua' file. The 'additional_activity_handler' function will be executed before sending the data to the PerimeterX portal.

Default: Only send activity to PerimeterX as controlled by 'pxconfig.lua'.

```lua
_M.additional_activity_handler = function(event_type, ctx, details)
	local cjson = require "cjson"
	if (event_type == 'block') then
		logger.warning("PerimeterX " + event_type + " blocked with score: " + ctx.score + "details " + cjson.encode(details))
	else
		logger.info("PerimeterX " + event_type + " details " +  cjson.encode(details))
	end
end
```

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

<a name="appendix"></a> Appendix
-----------------------------------------------

<a name="nginxplus"></a> NGINX Plus
-----------------------------------------------
The PerimeterX NGINX module is compatible with NGINX Plus. Users or administrators should install the NGINX Plus Lua dynamic module (LuaJIT).

<a name="dynamicmodules"></a> NGINX Dynamic Modules
-----------------------------------------------
If you are using NGINX with [dynamic module support](https://www.nginx.com/products/modules/) you can load the Lua module with the following lines at the beginning of your NGINX configuration file.

```
load_module modules/ndk_http_module.so;
load_module modules/ngx_http_lua_module.so;
```

<a name="contributing"></a> Contributing
----------------------------------------
The following steps are welcome when contributing to our project.

###Fork/Clone
[Create a fork](https://guides.github.com/activities/forking/) of the repository, and clone it locally.
Create a branch on your fork, preferably using a descriptive branch name.


###<a name="tests"></a>Test
> Tests for this project are written using the [`Test::Nginx`](https://github.com/openresty/test-nginx) testing framework.

**Dont forget to test**. This project relies heavily on tests, thus ensuring each user has the same experience, and no new features break the code.
Before you create any pull request, make sure your project has passed all tests. If any new features require it, write your own.

To run the tests, first build the docker container. Then, run the tests using the following command : `make docker-test`.

###Pull Request
After you have completed the process, create a pull request. Please provide a complete and thorough description explaining the changes. Remember, this code has to be read by our maintainers, so keep it simple, smart and accurate.

###Thanks
After all, you are helping us by contributing to this project, and we want to thank you for it.
We highly appreciate your time invested in contributing to our project, and are glad to have people like you - kind helpers.
