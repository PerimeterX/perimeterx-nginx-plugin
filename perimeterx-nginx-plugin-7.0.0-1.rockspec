 package = "perimeterx-nginx-plugin"
 version = "7.0.0-1"
 source = {
    url = "https://github.com/PerimeterX/perimeterx-nginx-plugin.git",
    tag = "v7.0.0",
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
