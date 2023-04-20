 package = "perimeterx-nginx-plugin"
 version = "7.2.1-1"
 source = {
    url = "git+https://github.com/PerimeterX/perimeterx-nginx-plugin.git",
    tag = "v7.2.1",
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
    "lua-resty-nettle < 1.0",
    "luasocket",
    "lustache"
 }

 build = {
    type = "make"
 }
