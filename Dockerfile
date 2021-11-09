FROM openresty/openresty:buster

ENV VER_LUA_NETTLE=1.5

RUN apt-get update && apt-get -qq -y install \
    build-essential \
    ca-certificates \
    curl \
    wget luarocks

# Install CPAN dependencies for unit tests
RUN curl -sSL http://cpanmin.us | perl - App::cpanminus
RUN cpanm --quiet --notest --skip-satisfied Test::Nginx
RUN cpanm --quiet --notest --skip-satisfied CryptX

RUN luarocks install lustache
RUN luarocks install luasocket
RUN luarocks install lua-resty-http
RUN luarocks install luacheck
RUN curl -sSL https://github.com/bungle/lua-resty-nettle/archive/v${VER_LUA_NETTLE}.tar.gz | tar -C /usr/local --strip-components 1 -xzf - && \
    mkdir -p /usr/local/lib/lua/resty && \
    mv /usr/local/lib/resty/* /usr/local/lib/lua/resty

RUN mkdir -p /tmp/px
COPY Makefile /tmp/px/
COPY lib /tmp/px/lib
COPY t /tmp/t
RUN make -C /tmp/px install

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY examples/creds.json /tmp/creds.json

# adjust local pxconfig.lua
#COPY pxconfig.lua /usr/local/lib/lua/px/

CMD ["nginx", "-g", "daemon off;"]
