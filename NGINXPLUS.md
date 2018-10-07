## <a name="installation_nginxplus_px_rhel"></a>Installing PerimeterX on NGINX+ With RHEL 7.4 And Above

The PerimeterX NGINX enforcer can be installed on **NGINX+ up to version R15**. <br/>
There is currently a known bug in R16 which crashes NGINX when calling `init_worker_by_lua_block`, required by the PerimeterX Enforcer.

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

1. In `nginx.conf` add the following to the top of the file:
	```lua
	load_module modules/ndk_http_module.so;
	load_module modules/ngx_http_lua_module.so;
	```

2. Add the `lua_package_path` and `lua_package_cpath` inside the `http` scope:
	```lua
	lua_package_path "/usr/local/lib/lua/?.lua;;";
	lua_package_cpath "/usr/lib64/lua/5.1/?.so;;";
	```

3.