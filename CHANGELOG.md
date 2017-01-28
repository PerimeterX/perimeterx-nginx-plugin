# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [2.3.0] - 2017-01-28
### Added
- Support Cookie V3 and Risk API V2 - single numeric score value, action on response
- Removed some redundant configurations

## [2.2.0] - 2017-01-05
### Added
- Added Optional Redirect Method (Inner Redirect / Browser Redirect).
- Added Redirection Methos Example Folder.

### Modified
- Updated README.
- Updated Examples.
- Modified The Default Block Page Look


### Fixed
- Fixed Multiple Application Support Caching Issue.
- Fixed URL Encoding Collisions

>Note: The Nginx module is currently supported up to version **1.11.6**

<br>




## [2.0.0] - 2016-12-07
### Added
- Multiple Application Support.
- Multiple Application Support Example.
- Filters now configurable via Config.

### Modified
- Updated Tests.
- Updated README.
- Updated Examples.

<br>

> **REQUIRES ACTION** :
> <br>
> **Updating from a previous version requires several changes** to the `pxconfig.lua` and `nginx.conf`.
> See `examples/Multiple Applications` files for reference.

1. In your `nginx.conf` file, replace `init_worker_by_lua_file` with `init_worker_by_lua_block { require ("px.utils.pxtimer").application() }`

2. In each of the location blocks in your app (each route protected with the module), replace `access_by_lua_file` (in each block of location) with `access_by_lua_block { require("px.pxnginx").application() }`

3. Compare your local `pxconfig.lua` file, with the config file located at `lib/px/pxconfig.lua`, adding in the whitelist filters to the configuration file. 

<br><br>



## [1.2.0] - 2016-11-29
### Added
- Page UUID to Risk API Request.
- Block Page Example.
- reCAPTCHA Block Page Example.
- Custom Block Page by URL.

### Modified
- Updated Examples.
- Updated README.
- Updated Tests.


## [1.1.4] - 2016-11-03
### Added
- Risk API UUID to context.
- Localized some global functions.

### Modified
- Clear captcha cookie on successful validation.
- Updated Documentation.
- Version header on all files.
- Update nginx.conf.
- Change text location.
- Created pxconstants.lua with readonly table
- Removed the full URL from pxblock.lua

### Fixed
- Block uuid monitor mode.
- Changed logo image.
- Fixed some links issues.

##[1.1.2] - 2016-10-20
### Added
- HTTP method to risk requests.


[1.2.0]: https://github.com/PerimeterX/perimeterx-nginx-plugin/tree/v1.2.0
[1.1.4]: https://github.com/PerimeterX/perimeterx-nginx-plugin/releases/tag/v1.1.4
[1.1.2]: https://github.com/PerimeterX/perimeterx-php-sdk/releases/tag/v1.3.15