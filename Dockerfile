# Based on manual compile instructions at http://wiki.nginx.org/HttpLuaModule#Installation
FROM ubuntu:14.04
ENV VER_NGINX_DEVEL_KIT=0.2.19
ENV VER_LUA_NGINX_MODULE=0.9.20
ENV VER_NGINX=1.7.10
ENV VER_LUAJIT=2.0.4
ENV NGINX_DEVEL_KIT ngx_devel_kit-${VER_NGINX_DEVEL_KIT}
ENV LUA_NGINX_MODULE lua-nginx-module-${VER_LUA_NGINX_MODULE}
ENV NGINX_ROOT=/nginx
ENV WEB_DIR ${NGINX_ROOT}/html
ENV LUAJIT_LIB /usr/local/lib
ENV LUAJIT_INC /usr/local/include/luajit-2.0
RUN apt-get update && apt-get --force-yes -qq -y install \
    build-essential \
    ca-certificates \
    curl \
    git \
    libpcre3 \
    libpcre3-dev \
    libssl-dev \
    lua-cjson \
    m4 \
    rsyslog \
    wget \
    zlib1g-dev
# ***** DOWNLOAD AND UNTAR *****
RUN curl -sSL http://nginx.org/download/nginx-${VER_NGINX}.tar.gz | tar xzf -
RUN curl -sSL http://luajit.org/download/LuaJIT-${VER_LUAJIT}.tar.gz | tar xzf -
RUN curl -sSL https://github.com/simpl/ngx_devel_kit/archive/v${VER_NGINX_DEVEL_KIT}.tar.gz | tar xzf -
RUN curl -sSL https://github.com/openresty/lua-nginx-module/archive/v${VER_LUA_NGINX_MODULE}.tar.gz | tar xzf -
RUN curl -sSL https://ftp.gnu.org/gnu/nettle/nettle-3.2.tar.gz | tar xzf -
RUN curl -sSL https://github.com/pintsized/lua-resty-http/archive/v0.08.tar.gz | tar xzf -
RUN curl -sSL https://github.com/bungle/lua-resty-nettle/archive/v0.95.tar.gz | tar -C /usr/local --strip-components 1 -xzf - && mkdir -p /usr/local/lib/lua/resty && mv /usr/local/lib/resty/* /usr/local/lib/lua/resty
# Install CPAN dependencies for unit tests
RUN curl -sSL http://cpanmin.us | perl - App::cpanminus
RUN cpanm --quiet --notest --skip-satisfied Test::Nginx 
RUN cpanm --quiet --notest --skip-satisfied CryptX
# ***** BUILD FROM SOURCE *****
# LuaJIT
WORKDIR /LuaJIT-${VER_LUAJIT}
RUN make && make install
# Nginx with LuaJIT
WORKDIR /nginx-${VER_NGINX}
RUN ./configure --prefix=${NGINX_ROOT} --with-ld-opt="-Wl,-rpath,${LUAJIT_LIB}" --add-module=/${NGINX_DEVEL_KIT} --add-module=/${LUA_NGINX_MODULE} --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module
RUN make && make install
RUN ln -s ${NGINX_ROOT}/sbin/nginx /usr/local/sbin/nginx
# Lua dependency packages
RUN ln -s /usr/lib/x86_64-linux-gnu/lua/5.1/cjson.so /usr/local/lib/lua/5.1/cjson.so
WORKDIR /lua-resty-http-0.08
RUN make install
# Install GNU Nettle
WORKDIR /nettle-3.2
RUN ./configure && make && make install
# PerimeterX Lua package
RUN mkdir -p /tmp/px
COPY Makefile /tmp/px/
COPY lib /tmp/px/lib
COPY t   /tmp/t
RUN make -C /tmp/px install
# ***** MISC *****
WORKDIR ${WEB_DIR}
EXPOSE 80
EXPOSE 8080
# ***** CLEANUP *****
RUN rm -rf \
    /nginx-${VER_NGINX} \
    /LuaJIT-${VER_LUAJIT} \
    /${NGINX_DEVEL_KIT} \
    /${LUA_NGINX_MODULE} \
    /lua-resty-http-0.08 \
    /nettle-3.2
COPY nginx.conf /nginx/conf/nginx.conf
# forward request and error logs to docker log collector
RUN mkdir -p /var/log/nginx
RUN touch /var/log/nginx/access.log
RUN touch /var/log/nginx/error.log
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log
# This is the default CMD used by nginx:1.9.2 image
CMD ["nginx", "-g", "daemon off;"]
