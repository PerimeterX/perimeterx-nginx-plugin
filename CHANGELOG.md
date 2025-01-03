# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).


## [7.3.4] - 2024-12-26
### Changed
- Automatically inspect GraphQL POST data

### Fixed
- GraphQL default path


## [7.3.3] - 2024-07-19
### Fixed
- Fix rate_limit code for JSON responses


## [7.3.2] - 2024-07-17
### Fixed
- Fix rate_limit code


## [7.3.1] - 2024-07-17
### Changed
- Remove lua-resty-nettle version restriction

### Fixed
- Install PX package symlink in OpenResty Lua directory


## [7.3.0] - 2023-06-13
### Added
- CORS support
- Set X-PX-COOKIES as the default custom cookie name
- `_M.px_login_creds_settings` configuration, to allow specify CI settings in Lua configuration file

### Changed
- rename "px_graphql_paths" to "px_graphql_routes"

### Fixed
- correctly add GraphQL routes (requests must contain specified GraphQL Type/Name) to sensitive routes


## [7.2.1] - 2023-04-20
### Added
- `custom_sensitive_routes` a custom function to determine if url path is a sensitive route


## [7.2.0] - 2023-04-13
### Added
- `custom_enabled_routes` a custom function to determine if url path is an enabled route
- `px_graphql_paths` to specify a list of GraphQL endpoints
- support for JWT and pxcts

### Changed
- support for multiple GraphQL endpoints

### Fixed
- Add CI paths to the sensitive routes


## [7.1.3] - 2022-06-27
### Fixed
- Export ngx.ctx.pxde variable


## [7.1.2] - 2022-06-22
### Fixed
- Properly handle multiple instances of the same header
- Fix field name in telemetry command


## [7.1.1] - 2022-05-10
### Fixed
- Call enrich_custom_parameters() only once


## [7.1.0] - 2022-04-20
### Added
- Credential Intelligence v2 protocol

### Changed
- Credential Intelligence v2 is the default protocol
- New block page

### Fixed
- Send custom_params with page_req and block activities


## [7.0.1] - 2022-03-21
### Added
- HypeSale support


## [7.0.0] - 2022-03-17
### Added
- GraphQL support
- sensitive_routes configuration

### Fixed
- Credential Intelligence code improvements and enhancement


## [6.8.0] - 2021-07-25
### Added
- Whitelist URI pattern support
- Page requested activity includes HTTP status code

## [6.7.3] - 2021-05-02
### Fixed
- Issue with request body in login credentials extraction

## [6.7.2] - 2021-03-20
### Added
- Support for form-urlencoded content type in login credentials extraction.

## [6.7.1] - 2021-03-19
### Added
- Support for multipart/form-data content type in login credentials extraction.
## [6.7.0] - 2021-03-17
### Added
- New feature: Login Credentials Extraction.

## [6.6.2] - 2020-10-16
### Fixed
- Handle cookies as tablee in `extract_cookie_names`.

## [6.6.1] - 2020-05-10
### Fixed
- Small logic fix in `extract_cookie_names` function.

## [6.6.0] - 2020-04-26
### Added
- Support for monitored routes.
- Support for secure flag for PXHD cookies.

### Fixed
- Removal of `gmatch` in `extract_cookie_names` for better performance.

## [6.5.1] - 2020-02-12
### Fixed
- Better iterations value validation.
- Full url parameter in risk_api calls.

## [6.5.0] - 2019-10-06
### Added
- Support for testing blocking flow in monitor mode.
- Support for custom cookie header

## [6.4.0] - 2019-08-27
### Fixed
- Refactoring of split string functions.

## [6.3.4] - 2019-08-25
### Fixed
- Linting related errors

## [6.3.3] - 2019-08-05
### Fixed
- orig_cookie is now a local variable
- additional_activity_handler now gets called regardless of send_page_requested settings.

## [6.3.2] - 2019-07-14
### Fixed
- Changed cookie variable from global to local

## [6.3.1] - 2019-06-23
### Fixed
- Accept header extraction for application/json.

## [6.3.0] - 2019-05-28
### Added
- Support for redirect to referer on challenge solve

## [6.2.2] - 2019-04-24
### Fixed
- Changed Payload from global to local variable

## [6.2.1] - 2019-04-23
### Fixed
- Additional check for proxy for http scheme in first party
- Changed global variables to local for pxcookie/pxtoken

## [6.2.0] - 2019-04-22
### Fixed
- Proxy connection pool key for activities and telemetry

### Added
- Enforcer telemetry by request

## [6.1.1] - 2019-04-16
### Fixed
- Proxy connection pool and scheme handling

## [6.1.0] - 2019-04-07
### Added
- Advanced blocking response enablement flag
- Proxy support

## [6.0.4] - 2019-01-15
### Fixed
- pxvid check for both pxvid and _pxvid cookies
- ignore ipv6 for whitelist ip filtering

## [6.0.3] - 2019-01-09
### Fixed
- s2s call reason of no_cookie_w_vid

## [6.0.2] - 2019-01-06
### Fixed
- PXHD cookie path

## [6.0.1] - 2019-01-04
### Fixed
- Mobile detection for captcha script

## [6.0.0] - 2019-01-02
### Added
- Added PXHD handling
- Added async custom params
- Major token and cookie refactoring

## [5.3.2] - 2018-11-13
### Fixed
- Cookie name extractor ability to handle multiple Cookie headers

## [5.3.1] - 2018-11-07
### Fixed
- Wrong value in Json response's vid property

## [5.3.0] - 2018-11-04
### Added
- Support for first party route prefix
- Sending cookie names on risk_api calls
- First party fallback for captcha file

## [5.2.0] - 2018-10-14
### Added
- Enrich Custom Parameters support
- Refreshed documentation for NGINX plus and RHEL 7.5

## [5.1.0] - 2018-09-26
### Added
- Support for Advanced Blocking Response

### Fixed
- Updated http/2 documentation section
- firstPartyEnabled property for Captcha

## [5.0.1] - 2018-09-02
### Added
- Refreshed documentation
- Support for url encoded cookies

## [5.0.0] - 2018-07-19
### Added
- Captcha v2 support
- CIDR support for `whitelist_ip_addresses` property

### Fixed
- Added properties back to pxconfig
- Documentation updates

## [4.1.0] - 2018-05-31
- Added data enrichment support

## [4.0.0] - 2018-05-22
- Added TLS prot/ciphers sha1
- Added handling timers when module disabled
- Added default config values
- Fixed case insensitive sensitive headers check
- Fixed mobile using first party path
- Enhanced error handling of first party routes

## [3.3.0] - 2018-02-19
- Update first party templates with fallback support
- Use relative URL for redirect in API protection mode
- Renamed vid cookie

## [3.2.1] - 2018-01-21
- Replaced default values for first party mode to false

## [3.2.0] - 2018-01-21
- Added support for first party remote configuration
- Disabled kong support for remote config and telemetry
- Fixed sensitive header cleaning on first party mode

## [3.1.0] - 2018-01-11
- Added support for first party
- Added support for rate limiting
- Supporting more variable for log enrichment
- Fixed sensitive headers filtering on captcha and activities
- Code optimizations

## [3.0.0] - 2017-12-03
- Added support for remote configurations
- Enhanced module logs
- Added support for score variable in logs
- Added mobile sdk pinning error
- Added support for enforcer telemetry
- Fixed mobile sdk header conditions

## [2.13.1] - 2017-12-01
### Fixed
- Added pcall on sending activities to prevent errors on server

## [2.13.0] - 2017-10-18
### Added
- Support for API protection in Kong plugin

## [2.12.0] - 2017-08-30
### Changed
- Removed luarocks dependency lua-cjosn (still needs to be installed via apt-get)
- Changed structure of pxconstants

## [2.11.0] - 2017-08-24
### Changed
- Changed default values for module mode to monitor
- Changed default value of blocksing score to 100

## [2.10.1] - 2017-08-10
### Fixed
- Removed PX snippet from block/captcha mustache
- Update the collectorUrl in mobile sdk response
- Added s2s_call_reason on mobile sdk connection error
- Fixed sending call_reason on cookie validation failed

## [2.10.0] - 2017-07-13
### Added
- Mobile SDK support
- Sensitive headers
- True IP headers list in configuration
### Modified
- Captcha cookie in base64 format in default captcha pages and examples

## [2.9.0] - 2017-06-27
### Modified
- Changed structure of captcha cookie

## [2.8.2] - 2017-06-23
### Fixed
- Timer function get_time_in_milliseconds

## [2.8.0] - 2017-06-04
### Added
- Support for funCaptcha. It is now possible to choose between reCaptcha and funCaptcha for the captcha page.
- New functionality - additional activity handler. The `additional_activity_handler` function will be executed before sending the data to the PerimeterX portal.
- Support for pass reason and risk RTT for better analytics.

## [2.7.0] - 2017-05-14
### Added
- Added support for sensitive routes

## [2.6.0] - 2017-03-22
### Added
- Added Javascript Challenge support
- Sending original cookie value when decryption fails
### Modified
- Using debug instead of error on several cases

## [2.5.0] - 2017-03-22
### Added
- New default block page design
- Inject custom css/js/logo to default block and captcha pages
### Modified
- Using app specific server url for api calls

## [2.4.0] - 2017-01-28
### Added
- New default block page design
### Fixed
- Bug preventing valid users to get cleaned up when module used default block page

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
