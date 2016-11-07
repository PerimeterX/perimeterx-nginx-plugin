 package = "perimeterx-nginx-plugin"
 version = "1.1-4"
 source = {
    url = "git://github.com/PerimeterX/perimeterx-nginx-plugin.git",
    tag = "v1.1.4",
 }
 description = {
    summary = "PerimeterX NGINX Lua Middleware.",
    detailed = [[
       This is an example for the LuaRocks tutorial.
       Here we would put a detailed, typically
       paragraph-long description.
    ]],
    homepage = "http://www.perimeterx.com",
    license = "MIT/PerimeterX"
 }
 dependencies = {
    "lua-cjson",
    "lua-resty-http",
    "lua-resty-nettle"
 }

 build = {
    type = "make"
 }