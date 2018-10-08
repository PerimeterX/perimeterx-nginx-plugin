## <a name="installation_nginxplus_px_rhel"></a>Installing PerimeterX on NGINX+ With RHEL 7.4 And Above

The PerimeterX NGINX plugin can be installed on **NGINX+ up to version R15**. <br/>
There is currently a known bug in R16 which crashes NGINX when calling `init_worker_by_lua_block` (required by the PerimeterX plugin). Until this bug is fixed, PerimeterX will not support installations using R16.

### Installation

1. Install the NGINX+ lua module (depending on the version of NGINX+ installed, example shows R15):
	```sh
	sudo yum install -y nginx-plus-module-lua-r15
	```

2. Make sure Nettle is removed:
	```sh
	sudo yum -y remove nettle
	```

3. Install the development tools:
	```sh
	sudo yum groupinstall -y "Development Tools"
	```

4. Compile and install Nettle from source:
	```sh
	mkdir /tmp
	cd /tmp/
	wget https://ftp.gnu.org/gnu/nettle/nettle-3.3.tar.gz
	tar -xzf nettle-3.3.tar.gz
	cd nettle-3.3
	./configure
	make
	sudo make install
	```

5. Install Luarocks and the PerimeterX Lua plugin dependencies:
	```sh
	sudo yum install -y luarocks lua-devel
	sudo luarocks install lua-cjson
	sudo luarocks install lustache
	sudo luarocks install lua-resty-nettle
	sudo luarocks install luasocket
	sudo luarocks install lua-resty-http
	```

6. Install the PerimeterX Module:
	```sh
	sudo luarocks install perimeterx-nginx-plugin
	```

### Configuration

1. Add the modules loading declaration at the top of the `nginx.conf` file:
	```lua
	load_module modules/ndk_http_module.so;
	load_module modules/ngx_http_lua_module.so;
	```

2. Add the `lua_package_path` and `lua_package_cpath` declarations inside the `http` scope:
	```lua
	lua_package_path "/usr/local/lib/lua/?.lua;;";
	lua_package_cpath "/usr/lib64/lua/5.1/?.so;;";
	```

3. Add the resolver directive: 
	The Resolver directive must be configured in the HTTP section of your NGINX configuration. <br/>
    * Set the resolver, `resolver A.B.C.D;`, to an external DNS resolver, such as Google (`resolver 8.8.8.8;`), 
   
   _or_ 
   
   * Set the resolver, `resolver A.B.C.D;`, to the internal IP address of your DNS resolver (`resolver 10.1.1.1;`).   
  
  This is required for NGINX to resolve the PerimeterX API.

4. Add the Lua CA Certificates:
	For TLS support to PerimeterX servers, configure Lua to point to the trusted certificate location.

    ```lua
    lua_ssl_trusted_certificate "/etc/pki/tls/certs/ca-bundle.crt";
	lua_ssl_verify_depth 3;
    ```

5. Add the Lua Timer Initialization
Add the init with a Lua script. The init is used by PerimeterX to hold and send metrics at regular intervals.

 ```lua
    init_worker_by_lua_block {
    	_NETTLE_LIB_PATH = "/usr/local/lib64"
    	local pxconfig = require("px.pxconfig")
    	require ("px.utils.pxtimer").application(pxconfig)
    }
```

6. Apply PerimeterX Enforcement
  Add the following line to your `location` block:

```
  #----- PerimeterX protect location -----#
  access_by_lua_block {
      local pxconfig = require("px.pxconfig")
      require ("px.pxnginx").application(pxconfig)
  }
  #----- PerimeterX Module End  -----#
```

  7. Continue with the [PerimeterX Plugin Configuration](https://github.com/PerimeterX/perimeterx-nginx-plugin#perimeterx-plugin-configuration) section.
