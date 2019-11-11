 package = "perimeterx-nginx-plugin"
 version = "6.3.3-2"
 source = {
    url = "git://github.com/PerimeterX/perimeterx-nginx-plugin.git",
    tag = "v6.3.3-2",
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
