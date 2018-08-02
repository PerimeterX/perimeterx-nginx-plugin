[![Build Status](https://travis-ci.org/PerimeterX/perimeterx-nginx-plugin.svg?branch=master)](https://travis-ci.org/PerimeterX/perimeterx-nginx-plugin)

![image](https://s.perimeterx.net/logo.png)

# [PerimeterX](http://www.perimeterx.com) NGINX Lua Plugin

> Latest stable version: [v4.1.0](https://luarocks.org/modules/bendpx/perimeterx-nginx-plugin/4.1-0)


## [Introduction](#introduction)

## [Upgrading](#upgradingVersions) 
* [From any Version Lower than 4.x](#3x4x)

## [Installation](#installation)
* [Supported Operating Systems](#supported_os)
* [Supported NGINX Versions](#supported_versions)
* [Installing with Ubuntu](#ubuntu)
* [Installing with CentOS7](centos7)
* [Installing the PerimeterX NGINX Plugin for NGINX+](#nstallation_nginxplus_px)  
* [Required NGINX Configuration](#nginx_configuration)
  * [Resolver](#nginx_resolver)
  * [Lua Package Path](#nginx_lua_package_path)
  * [Lua CA Certificates](#nginx_lua_ca_certificates)
  * [Lua Timer Initialization](#nginx_lua_timer_initialization)
  * [PerimeterX enforcement](#nginx_perimeterx_enforcement)
  * [NGINX.conf Example](#nginx_config_example)

## [Configuration](#configuration)
* [Required Configuration](#perimterx_required_parameters)
* [First-Party Configuration](#first_party_config)
  * [First-Party Mode](#first-party)
  * [PerimeterX First Party-JS Snippet](#perimterx_first_party_js_snippet)
* [Optional Configuration](#advanced_configuration)
  * [Monitor / Block Mode](#monitoring_mode)
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
  * [Additional Activity Handler](#add-activity-handler)
  * [Blocking Score](#blocking-score)

## [Enrichment](#enrichment)
 * [Data-Enrichment](#data-enrichment)
 * [Log Enrichment](#log-enrichment)
  
## [Appendix](#appendix)  
 * [NGINX Plus](#nginxplus)
 * [NGINX Dynamic Modules](#dynamicmodules)
 * [Multiple App Support](#multipleapps)
 * [Contributing](#contributing)

## <a name="introduction"></a> Introduction
The PerimeterX Nginx Lua Plugin is a Lua module that enforces whether or not
a request is allowed to continue being processed. When the PerimeterX Enforcer determines that a request is coming from a non-human source the request is blocked. 
 
## <a name="upgradingVersions"></a> Upgrading
See the full [changelog](CHANGELOG.md) for all versions.

#### <a name="3x4x"></a> From any Version Lower than 4.x

As of version 4.x the config builder was added. The config builder adds default values to properties that are not impicitly specified. This change requires the user to import the configuration in the `init_worker_by_lua_block` and `access_by_lua_block` blocks inside `nginx.conf`:
   
1. Modify `init_worker_by_lua_block`
```lua
    init_worker_by_lua_block {
        local pxconfig = require("px.pxconfig")
        require ("px.utils.pxtimer").application(pxconfig)
    }
```
2. Modify `access_by_lua_block`
```lua
            access_by_lua_block {
                local pxconfig = require("px.pxconfig")
                require("px.pxnginx").application(pxconfig)
            }
```

## <a name="installation"></a>Installation

#### <a name="supported_os"></a> Supported Operating Systems
* Debian
* [Ubuntu 14.04](#ubuntu1404) or [Ubuntu 16.04+](#ubuntu1604) 
* RHEL
* [CentOS 7](#centos7)
* Amazon Linux (AMI)

#### <a name="supported_versions"></a>Supported NGINX Versions:
Recomended that you use the newest version of NGINX from the [Official NGINX](http://nginx.org/en/linux_packages.html) repo. 
 
* [NGINX 1.7 or later](#installation_px)
  * [Lua NGINX Module V0.9.11 or later](#installation_px)
* [NGINX Plus](#installation_nginxplus_px)
  * [Lua NGINX Plus Module](#installation_nginxplus_px)
* [OpenResty](https://openresty.org/en/)

 > NOTE: Using the default NGINX provide by default in various Operating Systems does not support the LUA NGINX Module.

### <a name="ubuntu"></a> Installing with Ubuntu

#### <a name="ubuntu1404"></a>Ubuntu 14.04

###### 1. Upgrade and update your existing dependencies for Ubuntu 16.04 or higher
```sh
sudo apt-get update
sudo apt-get upgrade
```

###### 2. Add the offical NGINX repository to get the latest version of NGINX
```sh 
sudo add-apt-repository ppa:nginx/stable
```
  If an `add-apt-repository: command not found` error is returned, run:
 
  `sudo apt-get -y install software-properties-common`

###### 3. Install the dependencies for Ubuntu 14.04: 
```sh
sudo apt-get -y install build-essential
sudo apt-get -y install ca-certificates
sudo apt-get -y install make
sudo apt-get -y install wget
sudo apt-get -y install nginx
sudo apt-get -y install m4
sudo apt-get -y install libnginx-mod-http-lua
sudo apt-get -y install lua-cjson
```
###### 4. Download and install LuaRocks from source
```sh
wget http://luarocks.github.io/luarocks/releases/luarocks-2.4.4.tar.gz
tar -xzf luarocks-2.4.4.tar.gz
cd luarocks-2.4.4
./configure
sudo make clean && sudo make build && sudo make install
cd ~
```

###### 5. Download and install Netttle 3.3 from source 
```sh
wget https://ftp.gnu.org/gnu/nettle/nettle-3.3.tar.gz
tar -xzf nettle-3.3.tar.gz
cd nettle-3.3
./configure
sudo make clean && sudo make install
cd ~
```

###### 6. Install the remaining dependencies
```sh
sudo apt-get -y install lua-sec
sudo luarocks install lua-resty-nettle
```

###### 7. Install the PerimeterX NGINX Plugin
```sh
sudo no_proxy=1 luarocks install perimeterx-nginx-plugin
```

##
### <a name="ubuntu1604"></a>Ubuntu 16.04 and Higher

###### 1. Upgrade and update your existing dependencies for Ubuntu 16.04 or higher
```sh
sudo apt-get update
sudo apt-get upgrade
```

###### 2. Add the offical NGINX repository to get the latest version of NGINX
```sh 
sudo add-apt-repository ppa:nginx/stable
```
  If an `add-apt-repository: command not found` error is returned, run:
 
  `sudo apt-get -y install software-properties-common`

###### 3. Install the dependencies for Ubuntu 16.04 or higher
```sh
sudo apt-get -y install build-essential
sudo apt-get -y install ca-certificates
sudo apt-get -y install nginx
sudo apt-get -y install libnginx-mod-http-lua 
sudo apt-get -y install lua-cjson 
sudo apt-get -y install libnettle6 
sudo apt-get -y install nettle-dev 
sudo apt-get -y install luarocks 
sudo apt-get -y install luajit 
sudo apt-get -y install libluajit-5.1-dev
```

###### 4. Install the PerimeterX NGINX Plugin
```sh
luarocks install perimeterx-nginx-plugin
```

##
### <a name="centos7"></a>Installing with CentOS 7
NGINX does not provide an NGINX http lua module for CentOS/RHEL via an RPM. This means that you need to compile the Module from source. 

###### 1. Update and Install dependecies
```sh 
sudo yum -y update
sudo yum install -y epel-release
sudo yum update -y
sudo yum groupinstall -y  "Development Tools"
sudo yum install -y luarocks wget rpmdevtools git luajit luajit-devel openssl-devel zlib-devel pcre-devel gcc gcc-c++ make perl-ExtUtils-Embed lua-json lua-devel  ca-certificates 
sudo yum remove -y nettle
```

###### 2. Make a tmp directory to work in 
```sh
sudo mkdir /tmp/nginx
cd /tmp/nginx
```

###### 3. Download all required source files
```sh
wget http://nginx.org/download/nginx-1.13.11.tar.gz
wget http://luajit.org/download/LuaJIT-2.0.4.tar.gz
wget -O nginx_devel_kit.tar.gz https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz
wget -O nginx_lua_module.tar.gz https://github.com/openresty/lua-nginx-module/archive/v0.10.10.tar.gz
wget https://ftp.gnu.org/gnu/nettle/nettle-3.4.tar.gz
```

###### 4. Unpackage all source files
```sh
tar -xzf nettle-3.4.tar.gz
tar -xvf LuaJIT-2.0.4.tar.gz
tar -xvf nginx-1.13.11.tar.gz
tar -xvf nginx_devel_kit.tar.gz
tar -xvf nginx_lua_module.tar.gz
```

###### 5. Install Nettle from source
```sh
cd /tmp/nginx/nettle-3.4
sudo ./configure --prefix=/usr --disable-static 
sudo make
sudo make check
sudo make install
sudo chmod -v 755 /usr/lib/lib{hogweed,nettle}.so
sudo install -v -m755 -d /usr/share/doc/nettle-3.4
sudo install -v -m644 nettle.html /usr/share/doc/nettle-3.4
```
###### 6. Install LuaJIT
```
cd /tmp/nginx/LuaJIT-2.0.4
sudo make install
```

###### 7. Build and Install NGINX with required Modules 
```sh
cd /tmp/nginx/nginx-1.13.11
LUAJIT_LIB=/usr/local/lib LUAJIT_INC=/usr/local/include/luajit-2.0 \
./configure \
--user=nginx                          \
--group=nginx                         \
--prefix=/etc/nginx                   \
--sbin-path=/usr/sbin/nginx           \
--conf-path=/etc/nginx/nginx.conf     \
--pid-path=/var/run/nginx.pid         \
--lock-path=/var/run/nginx.lock       \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--with-http_gzip_static_module        \
--with-http_stub_status_module        \
--with-debug                          \
--with-http_ssl_module                \
--with-pcre                           \
--with-http_perl_module               \
--with-file-aio                       \
--with-http_realip_module             \
--add-module=/tmp/nginx/ngx_devel_kit-0.3.0 \
--add-module=/tmp/nginx/lua-nginx-module-0.10.10
sudo make install
sudo nginx -t
```

###### 8. Install PerimeterX Nginx Plugin & Dependencies 
```sh
sudo luarocks install luasec
sudo luarocks install lustache
sudo luarocks install lua-resty-nettle
sudo luarocks install luasocket
sudo luarocks install lua-resty-http
sudo luarocks install lua-cjson
sudo luarocks install perimeterx-nginx-plugin
```

###### 9. Optionalally, if you are testing in a new environment you may need to configure the following:
* Add the user "nginx"
   ```sh 
   sudo useradd --system --home /var/cache/nginx --shell /sbin/nologin --comment "nginx user" --user-group nginx
   ```

* Create a systemd service for NGINX
  ```sh
  sudo vi /usr/lib/systemd/system/nginx.service
  ```

* Paste the following in the file you just created: 
  ```text
  [Unit]
  Description=nginx - high performance web server
  Documentation=https://nginx.org/en/docs/
  After=network-online.target remote-fs.target nss-lookup.target
  Wants=network-online.target
  
  [Service]
  Type=forking
  PIDFile=/var/run/nginx.pid
  ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx.conf
  ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
  ExecReload=/bin/kill -s HUP $MAINPID
  ExecStop=/bin/kill -s TERM $MAINPID
  
  [Install]
  WantedBy=multi-user.target
  ```
* Enable and Start the NGINX Service
  ```sh
  sudo systemctl is-enabled nginx.service
  sudo systemctl start nginx.service 
  sudo systemctl enable nginx.service
  ```

### <a name="installation_nginxplus_px"></a>Installing the PerimeterX NGINX Plugin for NGINX+
If you are already using NGINX+ the following steps cover how to install the NGINX+ Lua Module & the PermimeterX NGINX Plugin. 

###### 1. Install the <a href="https://docs.nginx.com/nginx/admin-guide/dynamic-modules/lua/" onclick="window.open(this.href); return false;">Lua modules provided by NGINX</a>

* For Amazon Linux, CentOS, and RHEL:
  ```sh
  yum install nginx-plus-module-lua
  ```

* For Ubuntu:
  ```sh
  apt-get install nginx-plus-module-lua
  ```

###### 2. Remove Pre-installed Nettle
  ```sh
  sudo yum -y remove nettle
  ```

###### 3. Install Nettle from Source
Download and compile nettle using the version appropriate for your environment:

For Amazon Linux, CentOS, and RHEL:
  ```sh
  yum -y install m4 # prerequisite for nettle
  cd /tmp/
  wget https://ftp.gnu.org/gnu/nettle/nettle-3.3.tar.gz
  tar -xzf nettle-3.3.tar.gz
  cd nettle-3.3
  ./configure
  make clean && make install
  cd /usr/lib64 && ln -s /usr/local/lib64/libnettle.so.
  ```

###### 4. Install Luarocks and Dependencies 
  ```sh
  sudo yum install luarocks
  sudo luarocks install lua-cjson
  sudo luarocks install lustache
  sudo luarocks install lua-resty-nettle
  sudo luarocks install luasocket
  sudo luarocks install lua-resty-http

  sudo ln -s /usr/lib64/lua /usr/lib/lua
  ```

###### 5. Install PerimeterX NGINX Plugin
  ```sh
  sudo luarocks install perimeterx-nginx-plugin
  ```

###### 6. Modify Selinux (Consult with your internal System Administrator)
On CentOS 7 and other Linux operating systems you may need to modify or disable Selinux. If you get the following error:

`nginx: lua atpanic: Lua VM crashed, reason: runtime code generation failed, restricted kernel?`

You will need to make one of the following changes:
* To disable SELinux: `RUN setenforcer 0`
* To enable execmem for httpd_t: `RUN setsebool httpd_execmem 1 -P` 

## <a name="configuration"></a>Configuration

### <a name="nginx_configuration"></a>Required NGINX Configuration
The following NGINX Configurations are required to support the PerimeterX NGINX Lua Plugin:

* #### <a name="nginx_resolver"></a>Resolver
   The Resolver directive must be configured in the HTTP section of your NGINX configuration. 
    * Set the resolver, `resolver A.B.C.D;`, to an external DNS resolver, such as Google (`resolver 8.8.8.8;`), 
   
   _or_ 
   
   * Set the resolver, `resolver A.B.C.D;`, to the internal IP address of your DNS resolver (`resolver 10.1.1.1;`).   
  
  This is required for NGINX to resolve the PerimeterX API.

* #### <a name="nginx_lua_package_path"></a>Lua Package Path
  Ensure your Lua package path location in the HTTP section of your configuration reflects the location of the  installed PerimeterX  modules.

    ```
    lua_package_path "/usr/local/lib/lua/?.lua;;";
    ```

* #### <a name="nginx_lua_ca_certificates"></a>Lua CA Certificates
  For TLS support to PerimeterX servers, configure Lua to point to the trusted certificate location.

    ```
    lua_ssl_trusted_certificate "/etc/ssl/certs/ca-certificates.crt";
    lua_ssl_verify_depth 3;
    ```

    > NOTE: The certificate location may differ between Linux distributions. In CentOS/RHEL systems, the CA bundle location may be located at `/etc/pki/tls/certs/ca-bundle.crt`.

* #### <a name="nginx_lua_timer_initialization"></a>Lua Timer Initialization
  Add the init with a Lua script. The init is used by PerimeterX to hold and send metrics at regular intervals.

  ```
  init_worker_by_lua_block {
      local pxconfig = require("px.pxconfig")
      require ("px.utils.pxtimer").application(pxconfig)
  }
  ```

* #### <a name="nginx_perimeterx_enforcement"></a>Apply PerimeterX Enforcement
  Add the following line to your `location` block:

    ```
  #----- PerimeterX protect location -----#
  access_by_lua_block {
      local pxconfig = require("px.pxconfig")
      require ("px.utils.pxtimer").application(pxconfig)
  }
  #----- PerimeterX Module End  -----#
  ```

* #### <a name="nginx_config_example"></a> nginx.conf Example
  The following **nginx.conf** example contains the required directives with enforcement applied to the `location` block.
  
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
          local pxconfig = require("px.pxconfig")
          require ("px.utils.pxtimer").application(pxconfig)
      }

      lua_ssl_trusted_certificate "/etc/ssl/certs/ca-certificates.crt";
      lua_ssl_verify_depth 3;

      resolver 8.8.8.8;

      server {
          listen 80;

          location / {
              #----- PerimeterX protect location -----#
              access_by_lua_block {
                local pxconfig = require("px.pxconfig")
                require("px.pxnginx").application(pxconfig)
              }
              #----- PerimeterX Module End  -----#

              root   /nginx/www;
              index  index.html;
          }
      }
  }
  ```

> NOTE: The NGINX Configuration Requirements must be completed before proceeding to the next stage of installation.

### <a name="configuration"></a>PerimeterX Plugin Configuration

#### <a name="perimterx_required_parameters"></a>Required Configuration:
The following configurations are set in:

**`/usr/local/lib/lua/px/pxconfig.lua`**

 ```lua
  -- ## Required Parameters ##
  _M.px_appId = 'PX_APP_ID'
  _M.auth_token = 'PX_AUTH_TOKEN'
  _M.cookie_secret = 'COOKIE_KEY'
 ```
  
 - The PerimeterX **Application ID / AppId** and PerimeterX **Token / Auth Token** can be found in the Portal, in <a href="https://console.perimeterx.com/#/app/applicationsmgmt" onclick="window.open(this.href); return false;">**Applications**</a>.

 - PerimeterX **Risk Cookie / Cookie Key** can be found in the portal, in <a href="https://console.perimeterx.com/#/app/policiesmgmt" onclick="window.open(this.href); return false;">**Policies**</a>.

  The Policy from where the **Risk Cookie / Cookie Key** is taken must correspond with the Application from where the **Application ID / AppId** and PerimeterX **Token / Auth Token**


#### <a name="first_party_config"></a> First-Party Configuration

##### <a name="first-party"></a> First-Party Mode
  First-Party Mode enables the module to send/receive data to/from the sensor, acting as a reverse-proxy for client requests and sensor activities.

  First-Party Mode may require additional changes on the [JS Sensor Snippet](#perimterx_first_party_js_snippet). For more information, refer to the PerimeterX Portal.

  ```lua
  -- ## Additional Configuration Parameters ##
  ...
  _M.first_party_enabled = true
  ```

  The following routes must be enabled for First-Party Mode for the PerimeterX Lua module:
    - `/<PX_APP_ID without PX prefix>/xhr/*`
    - `/<PX_APP_ID without PX prefix>/init.js`

  - If the PerimeterX Lua module is enabled on `location /`, the routes are already open and no action is necessary.

  - If the PerimeterX Lua module is *not* enabled on  `location /`, add to your server block for NGINX:

  ```lua
  server {
      listen 80;

      location /<PX_APP_ID without PX prefix> {
          #----- PerimeterX protect location -----#
          access_by_lua_block {
            local pxconfig = require("px.pxconfig")
            require("px.pxnginx").application(pxconfig)
          }
          #----- PerimeterX Module End  -----#

          root   /nginx/www;
          index  index.html;
      }
  }
  ```

> NOTE: The PerimeterX NGINX Lua Plugin Configuration Requirements must be completed before proceeding to the next stage of installation.

##### <a name="perimterx_first_party_js_snippet"></a> First-Party JS Snippet

Ensure the [PerimeterX NGINX Lua Plugin](#perimterx_plugin_configuration) is configured before deploying the PerimeterX First-Party JS Snippet across your site. (Detailed instructions for deploying the PerimeterX First-Party JS Snippet can be found <a href="https://console.perimeterx.com/docs/applications.html?highlight=first%20party#first-party-sensor" onclick="window.open(this.href); return false;">here</a>.)

To deploy the PerimeterX First-Party JS Snippet:

##### 1. Generate the First-Party Snippet
  * Go to <a href="https://console.perimeterx.com/#/app/applicationsmgmt" onclick="window.open(this.href); return false;">**Applications**</a> >> **Snippet**. 
  * Select **First-Party**.
  * Select **Use Default Routes**.
  * Click **Copy Snippet** to generate the JS Snippet.
  
##### 2. Deploy the First-Party Snippet
  * Copy the JS Snippet and deploy using a tag manager, or by embedding it globally into your web template for which websites you want PerimeterX to run.

## <a name="advanced_configuration"></a> Optional Configuration

### <a name="monitoring_mode"></a>Monitor / Block Mode Configuration

  By default, the PerimeterX plugin is set to Monitor Only mode (`_M.block_enabled = false`).

  Adding the **_ M.block_enabled** flag and setting it to _true_ in the `pxconfig.lua` file activates the module to enforce blocking.

  The PerimeterX Module blocks requests that exceed the block score threshold. If a request receives a risk score that is equal to or greater than the block score, a block page is displayed.
  
### <a name="debug-mode"></a> Debug Mode

 Enables debug logging mode.

 **Default:** false (disabled)
 
  ```
  _M.px_debug = true
  ```
 
  When Enabled, PerimeterX debug messages should be in the following template:

   - For debug messages - `[PerimeterX - DEBUG] [APP_ID] - MESSAGE` <br />
   - For error messages - `[PerimeterX - ERROR] [APP_ID] - MESSAGE`

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
  
### <a name="whitelisting"></a> Whitelisting
  Whitelisting (bypassing enforcement) is configured in the `pxconfig.lua` file

  Several filters can be configured:

  ```javascript
       whitelist_uri_full = { _M.custom_block_url },
     whitelist_uri_prefixes = {},
     whitelist_uri_suffixes = {'.css', '.bmp', '.tif', '.ttf', '.docx', '.woff2', '.js', '.pict', '.tiff', '.eot', '.xlsx', '.jpg', '.csv', '.eps', '.woff', '.xls', '.jpeg', '.doc', '.ejs', '.otf', '.pptx', '.gif', '.pdf', '.swf', '.svg', '.ps', '.ico', '.pls', '.midi', '.svgz', '.class', '.png', '.ppt', '.mid', 'webp', '.jar'},
     whitelist_ip_addresses = {},
     whitelist_ua_full = {},
     whitelist_ua_sub = {} 
  ```
  
  | Filter Name | Value | Filters Request To |
  | ----------- | ----- | ------------------ |
  | **whitelist_uri_full** | `{'/api_server_full'}` | `/api_server_full?data=1` </br> but not to </br> `/api_server?data=1` |
  | **whitelist_uri_prefixes** | `{'/api_server'}` | `/api_server_full?data=1` </br> but not to </br>  `/full_api_server?data=1` |
  | **whitelist_uri_suffixes** | `{'.css'}` | `/style.css` </br> but not to </br>  `/style.js` |
  | **whitelist_ip_addresses** | `{'192.168.99.1'}` | Filters requests coming from any of the listed IPs. |
  | **whitelist_ua_full** | `{'Mozilla/5.0 (compatible; pingbot/2.0; http://www.pingdom.com/)'}` | Filters all requests matching this exact UA. |
  | **whitelist_ua_sub** | `{'GoogleCloudMonitoring'}` | Filters requests containing the provided string in their UA.


### <a name="sensitive-headers"></a> Filter Sensitive Headers
  A list of sensitive headers configured to prevent specific headers from being sent to PerimeterX servers (headers in lower case). Filtering cookie headers for privacy is set by default, and can be overridden on the `pxConfig` variable.
 
 **Default:** cookie, cookies

 Example:
  
  ```lua
  _M.sensitive_headers = {'cookie', 'cookies', 'secret-header'}
  ```

### <a name="remote-configurations"></a> Remote Configurations
 Allows the module to periodically pull configurations from PerimeterX services. When enabled, the configuration can be changed dynamically via PerimeterX Portal

 **Default:** false

 **File:** `pxconfig.lua`
    
 Example:
 
 ```lua
    ...
    _M.dynamic_configurations = false
    _M.load_interval = 5
    ...
  ```

### <a name="captcha-provider"></a>Select CAPTCHA Provider

  The CAPTCHA provider for the block page. </br>
 Possible Options:
  
  * [reCAPTCHA](https://www.google.com/recaptcha)

 **Default:** `reCaptcha`
 
 Example:
 
 ```lua
  _M.captcha_provider = "reCaptcha"
 ```

### <a name="enabled-routes"></a> Enabled Routes

 Allows you to define a set of routes on which the plugin will be active. An empty list sets all routes in the application as active.

 **Default:** Empty list (all routes are active)

 Example:
 
 ```lua
  _M.enabled_routes = {'/blockhere'}
  ```

### <a name="sensitive-routes"></a> Sensitive Routes

  A list of route prefixes and suffixes. The PerimeterX module always matches the request URI with the prefixes list and suffixes list. When there is a match, the PerimeterX module creates a server-to-server call, even when the cookie is valid and the risk score is low.

 **Default:** Empty list

 Example:

  ```lua
  _M.sensitive_routes_prefix = {'/login', '/user/profile'}
  _M.sensitive_routes_suffix = {'/download'}
  ```

### <a name="api-timeout"></a>API Timeout Milliseconds
API Timeout in milliseconds (float) to wait for the PerimeterX server API response.</br>
Controls the timeouts for PerimeterX requests. The API is called when a Risk Cookie does not exist, is expired, or is  invalid.

 **Default:** 1000
 
 Example:

 ```
  _M.s2s_timeout = 250
 ```

### <a name="customblockpage"></a> Customize Default Block Page

 The PerimeterX default block page can be modified by injecting custom CSS, JavaScript and a custom logo to the block page.

 **Default:** nil

 Example:

  ```
  _M.custom_logo = "http://www.example.com/logo.png"
  _M.css_ref = "http://www.example.com/style.css"
  _M.js_ref = "http://www.example.com/script.js"
  ```
### <a name="redirect_to_custom_blockpage"></a>Redirect to a Custom Block Page URL
 Customizes the block page to meet branding and message requirements by specifying the URL of the block page HTML file. The page can also implement CAPTCHA. 
 
 **Default:** nil
 
 Example:

  ```
  _M.custom_block_url = nil
  ```

  ```lua
  _M.custom_block_url = '/block.html'
  ```
  
  > Note: This URI is whitelisted automatically under `_M.Whitelist['uri_full'] ` to avoid infinite redirects.


### <a name="redirect_on_custom_url"></a> Redirect on Custom URL

  The `_M.redirect_on_custom_url` boolean flag to redirect users to a block page.

 **Default:** false
 
 Example:

```lua
  _M.redirect_on_custom_url = false
  ```

  By default, when a user exceeds the blocking threshold and blocking is enabled, the user is redirected to the block page defined by the `_M.custom_block_url` variable. The defined block page displays a **307 (Temporary Redirect)** HTTP Response Code.

  When the flag is set to false, a **403 (Unauthorized)** HTTP Response Code is displayed on the blocked page URL. </br>
  Setting the flag to true (enabling redirects) results in the following URL upon blocking:

 ```
  http://www.example.com/block.html?url=L3NvbWVwYWdlP2ZvbyUzRGJhcg==&uuid=e8e6efb0-8a59-11e6-815c-3bdad80c1d39&vid=08320300-6516-11e6-9308-b9c827550d47
 ```
  
  Setting the flag to false does not require the block page to include any of the examples below, as they are injected into the blocking page via the PerimeterX NGINX Enforcer.

  > NOTE: The URL variable should be built with the URL Encoded query parameters (of the original request) with both the original path and variables  Base64 Encoded (to avoid collisions with block page query params).

 #### Custom Block Pages Requirements

 As of version 4.0, Captcha logic is being handled through the JavaScript snippet and not through the Enforcer.

 Users who have Custom Block Pages must include the new script tag and a new div in the _.html_ block page. For implementation instructions refer to the appropriate links below:

 * [reCaptcha](examples/Custom Block Page + reCAPTCHA + Redirect/README.md)
 * [Custom Block Page](examples/Custom Block Page/README.md)

### <a name="multipleapps"></a> Multiple App Support

  The PerimeterX Enforcer allows multiple configurations for different applications.

  If your PerimeterX account contains several applications (as defined in the Portal), you can create different configurations for each application.

  > NOTE: The application initializes a timed Enforcer. The Enforcer must be initialized with one of the applications in your account. The the correct configuration file name must be passed to the `require ("px.utils.pxtimer").application("AppName"|empty)` block in the server initialization.

  1. Open the `nginx.conf` file, and locate the `require("px.pxnginx").application()` line inside your location block.
  2. Pass the desired application name into the `application()` function.</br>
    For example: `require("px.pxnginx").application("mySpecialApp")`
  3. Locate the `pxconfig.lua` file, and create a copy of it. </br> The copy name should follow the pattern: </br> `pxconfig-<AppName>.lua` (e.g. `pxconfig-mySpecialApp.lua`) </br> The < AppName > placeholder must be replaced by the exact name provided to the application function in step 1.
  4. Change the configuration in file created in step 3.
  5. Save the file in the location where pxnginx.lua file is located.   
   (Default location: `/usr/local/lib/lua/px/<yourFile>`)
  6. For every location block of your app, replace the code mentioned in step 2 with the correct < AppName >.

- ### <a name="add-activity-handler"></a> Additional Activity Handler
  An additional activity handler is added by setting `_M.additional_activity_handler` with a user defined function in the 'pxconfig.lua' file.

 **Default:** Activity is sent to PerimeterX as controlled by 'pxconfig.lua'.
 
 Example:

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

### <a name="log-enrichment"></a> Log Enrichment
 Access logs can be enriched with the PerimeterX bot information by creating an NGINX variable with the proper name. To configure this variable use the NGINX map directive in the HTTP section of your NGINX configuration file. This should be added before  additional configuration files are added.

  **The following variables are enabled:**
     
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

### <a name="blocking-score"></a> Changing the Minimum Score for Blocking
The PerimeterX NGINX plugin stores the data enrichment payload on the request context. The data enrichment payload can also be processed with `additional_activity_handler`.
  
Only requests that are *not* being block will reach the backend server, so specific logic must be applied to the processing function.

The following example includes the pre-condition checks required to process the data enrichment payload and enrich the request headers.  
 
```lua
    ... 
    _M.additional_activity_handler = function(event_type, ctx, details)
        -- verify that the request is passed to the backend
        if event_type == 'page_requested' then
          -- pxde - contains a parsed json of the data enrichment object
          -- pxde_verified - makes sure that this payload is trusted and signed by PerimeterX
          local pxde = ngx.ctx.pxde
          local pxde_verified = ngx.ctx.pxde_verified
          if pxde and pxde_verified then
              -- apply the data enrichment logic here
              -- the example below will set the f_type on the request header
              local f_type = ngx.ctx.pxde.f_type
              ngx.req.set_header("x-px-de-f-type", f_type)
          end
        end
    end
    ...
```
For more information and the available fields in the JSON, refer to the PerimeterX Portal documentation.
  
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
 Tests for this project are written using the [`Test::Nginx`](https://github.com/openresty/test-nginx) testing framework.

  **Don't forget to test**.

  This project relies heavily on tests to ensure that each user has the same experience, and no new features break the code. Before you create any pull request, make sure your project has passed all tests. If any new features require it, write your own test.

  To run the tests<br/>
  1. Build the docker container.
  2. Run the tests using the following command: make docker-test.

* ### Pull Request
  Once you have completed the process, create a pull request. Provide a complete and thorough description explaining the changes. Remember, the code has to be read by our maintainers, so keep it simple, smart and accurate.
