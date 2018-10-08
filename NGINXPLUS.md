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
  make install
  ```

###### 4. Install Luarocks and Dependencies 
  ```sh
  sudo yum install luarocks
  sudo luarocks install lua-cjson
  sudo luarocks install lustache
  sudo luarocks install lua-resty-nettle
  sudo luarocks install luasocket
  sudo luarocks install lua-resty-http
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