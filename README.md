[![Build Status](https://travis-ci.org/PerimeterX/perimeterx-nginx-plugin.svg?branch=master)](https://travis-ci.org/PerimeterX/perimeterx-nginx-plugin)

![image](https://s.perimeterx.net/logo.png)

# [PerimeterX](http://www.perimeterx.com) NGINX Lua Plugin

> Latest stable version: [v3.3.0](https://luarocks.org/modules/bendpx/perimeterx-nginx-plugin/3.3-0)

# [Getting Started](#getting_started)
* [Introduction](#introduction)
* [Install PerimeterX NGINX Lua Plugin](#installation_px)
   * [Required NGINX Configuration](#nginx_configuration)
   * [Resolver](#nginx_resolver)
   * [Lua Package Path](#nginx_lua_package_path)
   * [Lua CA Certificates](#nginx_lua_ca_certificates)
   * [Lua Timer Initialization](#nginx_lua_timer_initialization)
   * [PerimeterX enforcement](#nginx_perimeterx_enforcement)
   * [Example NGINX.conf](#nginx_config_example)
* [PerimeterX NGINX Lua Plugin Configuration](#perimterx_plugin_configuration)
   * [Required parameters](#perimterx_required_parameters)
   * [Monitor / Block Mode](#monitoring_mode)
   * [First Party Mode](#first-party)
* [PerimeterX First Party JS Snippet](#perimterx_first_party_js_snippet)

# [Advanced Configuration](#advanced_configuration)
* [Debug Mode](#debug-mode)
* [Extracting Real IP Address](#real-ip)
* [Whitelisting](#whitelisting)
* [Filter Sensitive Headers](#sensitive-headers)
* [Remote Configurations](#remote-configurations)
* [Select Captcha Provider](#captcha-provider)
* [Enabled Routes](#enabled-routes)
* [Sensitive Routes](#sensitive-routes)
* [API Timeout](#api-timeout)
* [Customize Default Block Page](#customblockpage)
* [Redirect to a Custom Block Page URL](#redirect_to_custom_blockpage)
* [Redirect on Custom URL](#redirect_on_custom_url)
* [Multiple App Support](#multipleapps)
* [Additional Activity Handler](#add-activity-handler)
* [Log Enrichment](#log-enrichment)
* [Blocking Score](#blocking-score)

-   [Appendix](#appendix)
  *   [NGINX Plus](#nginxplus)
  *   [NGINX Dynamic Modules](#dynamicmodules)
  *   [Contributing](#contributing)

# <a name="getting_started"></a> Getting Started

## <a name="introduction"></a> Introduction
The PerimeterX Nginx Lua Plugin is a lua module that enforcers whether or not
a request is allowed to continue to be processed or not. If PerimeterX has
determined that the request is coming from a non human source the request will
be blocked.  

## Installation

##### Supported Operating Systems
* Debian
* CentOS/RHEL
* Ubuntu
* Amazon Linux (AMI)

##### Supported NGINX Versions
* [Nginx 1.7 to 1.13.11](#installation_px)
  * [Lua Nginx Module V0.9.11 to V0.10.11](#installation_px)
* [Nginx Plus](#installation_nginxplus_px)
  * [Lua Nginx Plus Module](#installation_nginxplus_px)
* <a href="https://openresty.org/en/" onclick="window.open(this.href); return false;">OpenResty</a>

## <a name="installation_px"> Install PerimeterX Nginx Lua Plugin

#### 1. Install dependencies for corresponding Operating Systems

Ubuntu run:

```sh
sudo apt-get update && sudo apt-get install lua-cjson libnettle6 nettle-dev luarocks luajit libluajit-5.1-dev ca-certificates
```
CentOS run:
```sh
sudo yum -y groupinstall "Development Tools" && sudo yum -y install gcc gcc-c++ cmake kernel-devel zlib-devel cpio expat-devel gettext-devel libxslt libxslt-devel gd gd-devel perl-ExtUtils-Embed openssl openssl-devel lua-devel luarocks perl-Template-Toolkit perl-CPAN
```

#### 2. Install PerimeterX Nginx Plugin

Install using [luarocks](https://luarocks.org/).
```sh
luarocks install perimeterx-nginx-plugin
```

*OR*

Install manually, by downloading the repository and running `sudo make install`.

```sh
git clone https://github.com/PerimeterX/perimeterx-nginx-plugin.git
cd /perimeterx-nginx-plugin
sudo make install
```

## <a name="installation_nginxplus_px"> Install PerimeterX Nginx+ Lua Plugin

#### 1. Install the Lua modules provided by the NGINX team (via yum) and the CA certificates bundle required when configuring NGINX.

```
yum -y install nginx-plus-module-lua ca-certificates.noarch
```

#### 2. Download and compile nettle, using the version appropriate for your environment.
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

#### 3. Change the certificate path provided in the Lua CA Certificates section to the Amazon Linux trusted certificate:
```
lua_ssl_trusted_certificate "/etc/pki/tls/certs/ca-bundle.crt";
```

## <a name="nginx_configuration"></a>Required Nginx Configuration [Example Below](#nginx_config_example)
The following are the additional Nginx Configurations that are needed to support the PerimeterX NGINX Lua Plugin.

* ###### <a name="nginx_resolver"></a>Resolver
  In the HTTP section of your Nginx configuration you need to have the Resolver directive configured. You can set the resolver, `resolver A.B.C.D;`, to an external DNS resolver like Google `resolver 8.8.8.8;` or to the internal IP address of your DNS resolver `resolver 10.1.1.1;`.
  This is required for NGINX to resolve the PerimeterX API.

* ###### <a name="nginx_lua_package_path"></a>Lua Package Path
  Ensure your Lua package path location in the HTTP section of your configuration reflects where you have installed the Perimeterx modules.

    ```
    lua_package_path "/usr/local/lib/lua/?.lua;;";
    ```

* ###### <a name="nginx_lua_ca_certificates"></a>Lua CA Certificates
  For TLS support to PerimeterX servers, configure Lua to point to the trusted certificate location.

    ```
    lua_ssl_trusted_certificate "/etc/ssl/certs/ca-certificates.crt";
    lua_ssl_verify_depth 3;
    ```

    Note: Certificate location may differ between Linux distributions. In CentOS/RHEL systems, the CA bundle location may be located at `/etc/pki/tls/certs/ca-bundle.crt`.

* ###### <a name="nginx_lua_timer_initialization"></a>Lua Timer Initialization
  Add the init with a Lua script. The init is is used by PerimeterX to hold and send metrics at regular intervals.

  ```
  init_worker_by_lua_block {
      require ("px.utils.pxtimer").application()
  }
  ```

* ###### <a name="nginx_perimeterx_enforcement"></a>Apply PerimeterX enforcement
  Add the following line to your location block:

    ```
  #----- PerimeterX protect location -----#
  access_by_lua_block {
    require("px.pxnginx").application()
  }
  #----- PerimeterX Module End  -----#
  ```

* ###### <a name="nginx_config_example"></a>Example of nginx.conf
  nginx.conf containing the required directives and with enforcement applied to the location block.

  ###### nginx.conf:
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

### NOTE: The NGINX Configuration Requirements must be completed before proceeding to the next stage of installation.

## <a name="perimterx_plugin_configuration"><a/>Required PerimeterX Nginx Plugin Configuration
The following Configuration options are set in the file:

**`/usr/local/lib/lua/px/pxconfig.lua`**

* ###### <a name="perimterx_required_parameters"><a/>Required parameters:
  ```lua
  -- ## Required Parameters ##
  _M.px_appId = 'PX_APP_ID'
  _M.auth_token = 'PX_AUTH_TOKEN'
  _M.cookie_secret = 'COOKIE_KEY'
  ```
  PerimeterX **Application ID / AppId** & PerimeterX **Token / Auth Token** can be found under <a href="https://console.perimeterx.com/#/app/applicationsmgmt" onclick="window.open(this.href); return false;">Applications</a>.

  PerimeterX **Risk Cookie / Cookie Key** can be found under <a href="https://console.perimeterx.com/#/app/policiesmgmt" onclick="window.open(this.href); return false;">Polices</a>.

  Be sure to use the Risk Cookie under the Policy that is associated to the corresponding Application.

* ###### <a name="monitoring_mode"></a>Monitor / Block Mode

  By default, the PerimeterX plugin is set to Monitor Only mode (`_M.block_enabled = false`):

  ```lua
  -- ## Blocking Parameters ##
  _M.blocking_score = 100
  _M.block_enabled = false
  _M.captcha_enabled = true
  ```

  Setting the **_M.block_enabled** flag to **_true_** will activate the module to enforce blocking.

  The PerimeterX module will block requests crossing the block score threshold. If a request receives a risk score that is equal to or greater than the block score then the user will receive a block page.

* ###### <a name="first-party"></a> First Party Mode
  Enables the module to send/receive data to/from the sensor, acting as a "reverse-proxy" for client requests and sensor activities.

  First Party Mode may also require additional changes on the [JS Sensor Snippet](#perimterx_first_party_js_snippet). For more information, refer to the portal.

  ```lua
  -- ## Additional Configuration Parameters ##
  ...
  _M.first_party_enabled = true
  ```

  First Party Mode needs the following routes enabled for the PerimeterX Lua module:
    - `/<PX_APP_ID without PX prefix>/xhr/*`
    - `/<PX_APP_ID without PX prefix>/init.js`

    If the PerimeterX Lua module is enabled on `location /` the routes are already open and there is no action for you to take.

    If the PerimeterX Lua module is *NOT* enabled on  `location /` then within your server block you will need to add the following for nginx:

  ```lua
  server {
      listen 80;

      location /<PX_APP_ID without PX prefix> {
          #----- PerimeterX protect location -----#
          access_by_lua_block {
              require("px.pxnginx").application()
          }
          #----- PerimeterX Module End  -----#

          root   /nginx/www;
          index  index.html;
      }
  }
  ```

### NOTE: The PerimeterX NGINX Lua Plugin Configuration Requirements must be completed before proceeding to the next stage of installation.

## <a name="perimterx_first_party_js_snippet"><a/>PerimeterX First Party JS Snippet

Be sure that you have configured the [PerimeterX NGINX Lua Plugin](#perimterx_plugin_configuration) before deploying the PerimeterX First Party JS Snippet across your site.

Detailed instructions can be found <a href="https://console.perimeterx.com/docs/applications.html?highlight=first%20party#first-party-sensor" onclick="window.open(this.href); return false;">here</a> but below is a short how-to guide.

* ###### Generate First-Party Snippet
  * Go to <a href="https://console.perimeterx.com/#/app/applicationsmgmt" onclick="window.open(this.href); return false;">Applications</a> >> Snippet
  * Choose First-Party
  * Select to Use Default routes
  * Generate JS Snippet
* ###### Deploy First-Party Snippet
  * Copy Snippet and deploy using a tag manager or by embedding it globally into your web template for which websites you want PerimeterX to run.

# <a name="advanced_configuration"></a> Advanced Configuration


* ### <a name="debug-mode"></a> Debug Mode

  Enables debug logging mode.

  **Default:** false (disabled)
  ```
  _M.px_debug = true
  ```
  When Enabled, PerimeterX debug messages should be in the following template:

  `[PerimeterX - DEBUG] [APP_ID] - MESSAGE` - for debug messages <br />
  `[PerimeterX - ERROR] [APP_ID] - MESSAGE` - for error messages

  Valid request flow example:
  ```
  2017/12/04 12:04:18 [error] 7#0: *9 [lua] pxlogger.lua:29: debug(): [PerimeterX - DEBUG] [ APP_ID ] - Cookie V3 found - Evaluating, client: 172.17.0.1, server: , request: "GET / HTTP/1.1", host: "localhost:8888"
  2017/12/04 12:04:18 [error] 7#0: *9 [lua] pxlogger.lua:29: debug(): [PerimeterX - DEBUG] [ APP_ID ] - cookie is encyrpted, client: 172.17.0.1, server: , request: "GET / HTTP/1.1", host: "localhost:8888"
  2017/12/04 12:04:18 [error] 7#0: *9 [lua] pxlogger.lua:29: debug(): [PerimeterX - DEBUG] [ APP_ID ] - Cookie evaluation ended successfully, risk score: 0, client: 172.17.0.1, server: , request: "GET / HTTP/1.1", host: "localhost:8888"
  2017/12/04 12:04:18 [error] 7#0: *9 [lua] pxlogger.lua:29: debug(): [PerimeterX - DEBUG] [ APP_ID ] - Sent page requested acitvity, client: 172.17.0.1, server: , request: "GET / HTTP/1.1", host: "localhost:8888"
  2017/12/04 12:04:18 [error] 7#0: *9 [lua] pxlogger.lua:29: debug(): [PerimeterX - DEBUG] [ APP_ID ] - Request is internal. PerimeterX processing skipped., client: 172.17.0.1, server: , request: "GET / HTTP/1.1", host: "localhost:8888"
  2017/12/04 12:04:19 [error] 7#0: *63 [lua] pxlogger.lua:29: debug(): [PerimeterX - DEBUG] [ APP_ID ] - POST response status: 200, context: ngx.timer
  2017/12/04 12:04:19 [error] 7#0: *63 [lua] pxlogger.lua:29: debug(): [PerimeterX - DEBUG] [ APP_ID ] - Reused conn times: 3, context: ngx.timer
  ```

* ### <a name="real-ip"></a> Extracting the Real IP Address from a Request

  The PerimeterX module requires the user's real IP address.The real connection IP must be properly extracted when your NGINX server sits behind a load balancer or CDN.
  For the PerimeterX NGINX module to see the real user's IP address, you must have at least one of the following:
  - The set_real_ip_from and real_ip_header NGINX directives in your nginx.conf. This will ensure the connecting IP is properly derived from a trusted source.
  Example:
  ```
  set_real_ip_from 172.0.0.0/8;
  set_real_ip_from 107.178.0.0/16;
  real_ip_header X-Forwarded-For;
  ```
  - Set ip_headers, a list of headers from which to extract the real IP (ordered by priority).    
  **Default with no predefined header: `ngx.var.remote_addr`**
  Example:
  ```lua
  _M.ip_headers = {'X-TRUE-IP', 'X-Forwarded-For'}
  ```

* ### <a name="whitelisting"></a> Whitelisting
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

  - **uri_full** : for value `{'/api_server_full'}` - Filters requests to `/api_server_full?data=1` but not to `/api_server?data=1`
  - **uri_prefixes** : for value `{'/api_server'}` - Filters requests to `/api_server_full?data=1` but not to `/full_api_server?data=1`
  - **uri_suffixes** : for value `{'.css'}` - Filters requests to `/style.css` but not to `/style.js`
  - **ip_addresses** : for value `{'192.168.99.1'}` - Filters requests coming from any of the listed ips.
  - **ua_full** : for value `{'Mozilla/5.0 (compatible; pingbot/2.0;  http://www.pingdom.com/)'}` - Filters all requests matching this exact UA.
  - **ua_sub** : for value `{'GoogleCloudMonitoring'}` - Filters requests containing the provided string in their UA.


* ### <a name="sensitive-headers"></a> Filter Sensitive Headers
  A list of sensitive headers can be configured to prevent specific headers from being sent to PerimeterX servers (lower case header names). Filtering cookie headers for privacy is set by default, and can be overridden on the `pxConfig` variable.

  **Default: cookie, cookies**

  ```lua
  _M.sensitive_headers = {'cookie', 'cookies', 'secret-header'}
  ```

* ### <a name="remote-configurations"></a> Remote Configurations
    Remote configuration allows the module to periodically pull configurations from PerimeterX services. When enabled, the configuration can be changed dynamically via PerimeterX portal

    Default: false

    File: `pxconfig.lua`
    ```lua
    ...
    _M.dynamic_configurations = true
    _M.load_interval = 5
    ...
    ```


* ### <a name="captcha-provider"></a>Select CAPTCHA Provider

  The CAPTCHA provider for the block page is one of the following:
  * [reCAPTCHA](https://www.google.com/recaptcha)
  * [FunCaptcha](https://www.funcaptcha.com/)

  **Default: 'reCaptcha'**
  ```lua
  _M.captcha_provider = "funCaptcha"
  ```

* ### <a name="enabled-routes"></a> Enabled Routes

  The enabled routes variable allows you to implicitly define a set of routes on which the plugin will be active. An empty list sets all application routes as active.

  **Default: Empty list (all routes)**

  ```lua
  _M.enabled_routes = {'/blockhere'}
  ```

* ### <a name="sensitive-routes"></a> Sensitive Routes

  A list of route prefixes and suffixes. The PerimeterX module always matches the request URI with the prefixes and suffixes lists. When a match is found, the PerimeterX module creates a server-to-server call, even when the cookie is valid and its score is low.

  **Default: Empty list**

  ```lua
  _M.sensitive_routes_prefix = {'/login', '/user/profile'}
  _M.sensitive_routes_suffix = {'/download'}
  ```


* ### <a name="api-timeout"></a>API Timeout Milliseconds
  > Note: Controls the timeouts for PerimeterX requests. The API is called when a Risk Cookie does not exist, is expired, or is  invalid.

  API Timeout in milliseconds (float) to wait for the PerimeterX server API response.

  **Default:** 1000

  ```
  _M.s2s_timeout = 250
  ```


* ### <a name="customblockpage"></a> Customize Default Block Page

  Block pages can be customized with one of the following methods:
  ##### Modifying default block pages
  The PerimeterX default block page can be modified by injecting custom css, javascript and logo to the block page.

  **Default:** nil

  Example:

  ```
  _M.custom_logo = "http://www.example.com/logo.png"
  _M.css_ref = "http://www.example.com/style.css"
  _M.js_ref = "http://www.example.com/script.js"
  ```

* ### <a name="redirect_to_custom_blockpage"></a>Redirect to a Custom Block Page URL
  Users can customize the blocking page to meet their branding and message requirements by specifying the URL to a blocking page HTML file. The page can also implement reCaptcha. See <docs location> for more examples of a customized reCaptcha page.

  **Default:** nil

  ```
  _M.custom_block_url = nil
  ```

  > Note: This URI is whitelisted automatically under `_M.Whitelist['uri_full'] ` to avoid infinite redirects.

  ##### Blocked user example:

  If a user is blocked when browsing to `http://www.mysite.com/coolpage`, and the server configuration is:

  ```lua
  _M.custom_block_url = '/block.html'
  ```

* ### <a name="redirect_on_custom_url"></a> Redirect on Custom URL
  The `_M.redirect_on_custom_url` flag provides 2 options for redirecting users to a block page.

  **Default:** false

  ```lua
  _M.redirect_on_custom_url = false
  ```

  By default, when a user exceeds the blocking threshold and blocking is enabled, the user is redirected to the block page defined by the `_M.custom_block_url` variable, The defined block page displays a 307 (Temporary Redirect) HTTP Response Code.

  When the flag is set to false, a 403 (Unauthorized) HTTP Response Code is displayed on the blocked page URL.
  Setting the flag to true (enabling redirects) results in the following URL upon blocking:

  ```
  http://www.example.com/block.html?url=L3NvbWVwYWdlP2ZvbyUzRGJhcg==&uuid=e8e6efb0-8a59-11e6-815c-3bdad80c1d39&vid=08320300-6516-11e6-9308-b9c827550d47
  ```
  Setting the flag to false does not require the block page to include any of the examples below, as they are injected into the blocking page via the PerimeterX Nginx Enforcer.

  > Note: The URL variable is comprised of URL Encoded query parameters (of the original request) and then both the original path and variables are Base64 Encoded (to avoid collisions with block page query params).

  ###### Custom Blockpage Requirements:

  When CAPTCHA is enabled, and `_M.redirect_on_custom_url` is set to **true**, the block page **must** include the following:

  * The `<head>` section **must** include:

  ```html
  <script src="https://www.google.com/recaptcha/api.js"></script>
  <script>
  function handleCaptcha(response) {
      var vid = getQueryString("vid"); // getQueryString is implemented below
      var uuid = getQueryString("uuid");
      var name = '_pxCaptcha';
      var expiryUtc = new Date(Date.now() + 1000 * 10).toUTCString();
      var cookieParts = [name, '=', btoa(JSON.stringify({r: response, v:vid, u:uuid})), '; expires=', expiryUtc, '; path=/'];
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

  * The [PerimeterX Javascript snippet](https://console.perimeterx.com/#/app/applicationsmgmt) (available on the PerimeterX Portal via this link) must be pasted in.

  #### Configuration Example:

  ```lua
  _M.custom_block_url = '/block.html'
  _M.redirect_on_custom_url = true
  ```

  #### Block Page Implementation Full Example:

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
              var cookieParts = [name, '=', btoa(JSON.stringify({r: response, v:vid, u:uuid})), '; expires=', expiryUtc, '; path=/'];
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

* ### <a name="multipleapps"></a> Multiple App Support
  The PerimeterX Enforcer allows for multiple configurations for different apps.

  If your PerimeterX account contains several Applications (as defined in the portal), you can create different configurations for each Application.

  >Note: The application initializes a timed worker. The worker must be initialized with one of the applications in your account. The the correct configuration file name must be passed to the `require ("px.utils.pxtimer").application("AppName"|empty)` block in the server initialization.

  - Open the `nginx.conf` file, and find the following line : `require("px.pxnginx").application()` inside your location block.
  - Pass the desired application name into the `application()` function.
    For example: `require("px.pxnginx").application("mySpecialApp")`
  - Locate the `pxconfig.lua` file, and create a copy of it.
    The copy name should follow the pattern: `pxconfig-<AppName>.lua` (e.g. `pxconfig-mySpecialApp.lua`) - The <AppName> The placeholder must be replaced by the exact name provided to the application function in step 1.
  - Change the configuration iin created file.
  - Save the file in the location where pxnginx.lua file is located. (Default location: `/usr/local/lib/lua/px/<yourFile>`)
  - For every location block of your app, replace the code mentioned in step 2 with the correct AppName.

* ### <a name="add-activity-handler"></a> Additional Activity Handler
  An additional activity handler is added by setting `_M.additional_activity_handler` with a user defined function in the 'pxconfig.lua' file.

  Default: Activity is sent to PerimeterX as controlled by 'pxconfig.lua'.

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

* ### <a name="log-enrichment"></a> Log Enrichment
  Access logs can be enriched with the PerimeterX bot information by creating an NGINX variable with the proper name. To configure this variable use the NGINX map directive in the HTTP section of your NGINX configuration file. This should be added before  additional configuration files are added.

  #### The following variables are enabled:   
  * **Request UUID**: `pxuuid`
  * **Request VID**: `pxvid`
  * **Risk Round Trimp**: `pxrtt`
  * **Risk Score**: `pxscore`
  * **Pass Reason**: `pxpass`
  * **Block Reason**: `pxblock`
  * **Cookie Validity**: `pxcookiets`
  * **Risk Call Reason**: `pxcall`


  ```lua
  ....
  http {
      map score $pxscore  { default 'none'; }
      map pass $pxpass  { default 'none'; }
      map uuid $pxuuid  { default 'none'; }
      map rtt $pxrtt { default '0'; }
      map block $pxblock { default 'none'; }
      map vid $pxvid { default 'none'; }
      map cookiets $pxcookiets { default 'none'; }
      map px_call $pxcall { default 'none'; }

      log_format enriched '$remote_addr - $remote_user [$time_local] '
                      '"$request" $status $body_bytes_sent '
                      '"$http_referer" "$http_user_agent" '
                      '| perimeterx uuid[$pxuuid] vid[$pxvid] '
                      'score[$pxscore] rtt[$pxrtt] block[$pxblock] '
                      'pass[$pxpass] cookie_ts[$pxcookiets] risk_call[$pxcall]';

	    access_log /var/log/nginx/access_log enriched;

    }
    ...
  ```

* ### <a name="blocking-score"></a> Changing the Minimum Score for Blocking

  **Default blocking value:** 100

  This value should never be changed from the default of 100 unless advised by PerimeterX.
  ```
  _M.blocking_score = 100
  ```

<a name="appendix"></a> Appendix
-----------------------------------------------

* ### <a name="nginxplus"></a> NGINX Plus
  The PerimeterX NGINX module is compatible with NGINX Plus. Users or administrators should install the NGINX Plus Lua dynamic module (LuaJIT).

* ### <a name="dynamicmodules"></a> NGINX Dynamic Modules

  If you are using NGINX with [dynamic module support](https://www.nginx.com/products/modules/) you can load the Lua module with the following lines at the beginning of your NGINX configuration file.

  ```
  load_module modules/ndk_http_module.so;
  load_module modules/ngx_http_lua_module.so;
  ```

<a name="contributing"></a> Contributing
----------------------------------------
The following steps are welcome when contributing to our project.

* ### Fork/Clone
  [Create a fork](https://guides.github.com/activities/forking/) of the repository, and clone it locally.
  Create a branch on your fork, preferably using a descriptive branch name.


* ### <a name="tests"></a>Test
  > Tests for this project are written using the [`Test::Nginx`](https://github.com/openresty/test-nginx) testing framework.

  **Dont forget to test**.

  This project relies heavily on tests to ensure that each user has the same experience, and no new features break the code. Before you create any pull request, make sure your project has passed all tests. If any new features require it, write your own test.

  To run the tests<br/>
  1. Build the docker container.
  2. Run the tests using the following command: make docker-test.

* ### Pull Request
  Once you have completed the process, create a pull request. Provide a complete and thorough description explaining the changes. Remember, the code has to be read by our maintainers, so keep it simple, smart and accurate.

* ### Thanks
  After all, you are helping us by contributing to this project, and we want to thank you for it. We highly appreciate your time invested in contributing to our project, and are glad to have people like you - kind helpers.
