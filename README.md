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
  *   [Custom Block Page](#custom-block)
  *   [Monitoring mode](#monitoring-mode)
  *   [Enable/Disable Captcha](#captcha-support)
  *   [Enabled Routes](#enabled-routes)
  *   [API Timeout Milliseconds](#api-timeout)
  *   [Send Page Activities](#send-page-activities)
  *   [Debug Mode](#debug-mode)
  *   [Custom Block Page](#customblockpage)
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

To apply the PerimeterX enforcement add the following line in your location block.

`access_by_lua_file /usr/local/lib/lua/px/pxnginx.lua;`

Below is a complete example of nginx.conf containing the required directives and with enforcement applied to the location block /.

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

### Extracting the real IP address from a request

> Note: IP extraction, according to your network setup, is very important. It is common to have a load balancer/proxy on top of your applications, in which case the PerimeterX module will send the system's internal IP as the user's. In order to properly perform processing and detection on server-to-server calls, the PerimeterX module requires the user's real IP address.

For the NGINX module to work with the real user's IP you need to set the `set_real_ip_from` NGINX directive in your nginx.conf, this will make sure the socket IP used in nginx is not coming from one of the network levels below it.

example:
```
  set_real_ip_from 172.0.0.0/8;
  set_real_ip_from 107.178.0.0/16;	
 ```

### <a name="configuration"></a> Configuration Options

#### Configuring Required Parameters

Configuration options are set in the file `/usr/local/lib/lua/px/pxconfig.lua`:

#### Required parameters:

- px_appId
- cookie_secret
- auth_token

#### <a name="blocking-score"></a> Changing the Minimum Score for Blocking

**Default blocking value:** 70

```
_M.blocking_score = 60
```

#### <a name="custom-block"></a> Serve a Custom Block/reCAPTCHA Page
The Perimeterx allows serving the client a customized block page, when a user crosses the defined blocking thershold, and the Enforcer is set to Blocking Mode (default behaviour).
>Note: Perimeterx will serve the user with our default blocking screen when no custom page is defined.

######Customizing the Block Page
Open the file `pxblock.lua` located at `/lib/px/block/`.
Create a copy of the file for backup purposes. `pxblock.lua.orig`.
In this file (line 51), under `ngx_say`, there is an inline html containing PerimeterX's default blocking page.
At the end of that html, you will find the ref_str variable.

You may change the html as you wish, keeping the `<br> <br>
</br>' .. ref_str .. '​</div></body></html>')` in place.

[Custom Blocking Page Example](http://github.somewhere)

######Customizing the reCAPTCHA Page
Open the file `pxblock.lua` located at `/lib/px/block/`.
Create a copy of the file for backup purposes. `pxblock.lua.orig`.
In this file,there are 2 variables storing HTML - `head` and `body`. Both of these variables are changable, but must not alter the contents of the part quoted below:

For `head` :

```javascript
<script src="https://www.google.com/recaptcha/api.js"></script>
<script> window.px_vid = "' .. vid .. '"; function handleCaptcha(response) { var 
name = "_pxCaptcha"; var expiryUtc = new Date( Date.now() + 1000 * 10 ).toUTCString(); 
var cookieParts = [name, "=", response + ":" + window.px_vid, "; expires=", expiryUtc, ";
path=/"]; document.cookie = cookieParts.join(""); location.reload(); } </script>
```
For `body` :

```
<div class="g­recaptcha" data­sitekey="6Lcj­R8TAAAAABs3FrRPuQhLMbp5QrHsHufzLf7b" 
data­callback="handleCaptcha" data­theme="dark"></div><br> </br> ' .. ref_str .. ' </div>; 
```
These code bits are required in order to use our reCAPTCHA, and allow cleaning of user's bad score.

[Custom reCAPTCHA Page Example](http://github.somewhere)

#### <a name="monitoring-mode"></a> Monitoring Mode
By default the PerimeterX module will block users crossing the block score threshold you define, meaning, if a user crosses the minimum block score he will receive the block page. The PerimeterX plugin can also be activated in monitor only mode.
Setting the block_enalbed flag to false will prevent the block page from being displayed to the user, but the data will still be available in the PerimeterX Portal.

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

Boolean flag to enable or disable sending of activities and metrics to PerimeterX on each page request. Enabling this feature will provide data that populates the PerimeterX portal with valuable information such as the amount of requests blocked and additional API usage statistics.

**Default:** false

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

Users can customize the blocking page to meet their branding and message requirements. Specify the URL to a blocking page html file. The page can also implement reCaptcha. See <docs location> for more examples of a customized reCaptcha page.


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

When captcha is enabled, the block page **must** include:

* Inside the `<head>` section:

```html
<script src="https://www.google.com/recaptcha/api.js"></script>
<script>
function handleCaptcha(response) {
    var vid = getQueryString("vid"); // getQueryString should be implemented 
    var name = '_pxCaptcha';
    var expiryUtc = new Date(Date.now() + 1000 * 10).toUTCString();
    var cookieParts = [name, '=', response + ':' + vid + '; expires=', expiryUtc, '; path=/'];
    document.cookie = cookieParts.join('');
    var originalURL = getQueryString("url");
    var originalHost = window.location.host;
    window.location.href = window.location.protocol + "//" +  originalHost + originalURL;
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


#### Block page implementation example: 

```html
<html>
    <head>
        <script src="https://www.google.com/recaptcha/api.js"></script>
        <script>
        function handleCaptcha(response) {
            var vid = getQueryString("vid");
            var name = '_pxCaptcha';
            var expiryUtc = new Date(Date.now() + 1000 * 10).toUTCString();
            var cookieParts = [name, '=', response + ':' + vid, '; expires=', expiryUtc, '; path=/'];
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
The following steps are welcome when contributing to our project.
###Fork/Clone
First and foremost, [Create a fork](https://guides.github.com/activities/forking/) of the repository, and clone it locally.
Create a branch on your fork, preferably using a self descriptive branch name.

###Code/Run
Code your way out of your mess, and help improve our project by implementing missing features, adding capabilites or fixing bugs.

To run the code, simply follow the steps in the [installation guide](#installation). Grab the keys from the PerimeterX Portal, and try refreshing your page several times continously. If no default behaviours have been overriden, you should see the PerimeterX block page. Solve the CAPTCHA to clean yourself and start fresh again.

Feel free to check out the [Example App](https://nginx-sample-app.perimeterx.com), to have a feel of the project.

###<a name="tests"></a>Test
> Tests for this project are written using the [`Test::Nginx`](https://github.com/openresty/test-nginx) testing framework.

**Dont forget to test**. The project relies heavily on tests, thus ensuring each user has the same experience, and no new features break the code.
Before you create any pull request, make sure your project has passed all tests, and if any new features require it, write your own.

To run the tests, first build the docker container. Then, run the tests using the following command : `make docker-test`

###Pull Request
After you have completed the process, create a pull request to the Upstream repository. Please provide a complete and thorough description explaining the changes. Remember this code has to be read by our maintainers, so keep it simple, smart and accurate.

###Thanks
After all, you are helping us by contributing to this project, and we want to thank you for it.
We highly appreciate your time invested in contributing to our project, and are glad to have people like you - kind helpers.
