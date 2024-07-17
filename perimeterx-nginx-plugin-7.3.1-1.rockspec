 package = "perimeterx-nginx-plugin"
 version = "7.3.1-1"
 source = {
    url = "git+https://github.com/PerimeterX/perimeterx-nginx-plugin.git",
    tag = "v7.3.1",
 }
 description = {
    summary = "PerimeterX NGINX Lua Middleware.",
    detailed = [[
    ]],
    homepage = "http://www.perimeterx.com",
    license = "MIT/PerimeterX"
 }
 dependencies = {
    "lua-resty-http",
    "lua-resty-nettle",
    "luasocket",
    "lustache"
 }

 build = {
    type = "make"
 }
