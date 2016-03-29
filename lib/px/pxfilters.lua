----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.0
-- Release date: 21.02.2015
----------------------------------------------

local FILTERS = {}

FILTERS.Whitelist = {};

-- Full URI filter
-- will filter requests where the uri starts with any of the list below.
-- example:
-- filter: example.com/api_server_full?data=data
-- will not filter: example.com/api_server?data=data
-- FILTERS.Whitelist['uri_full'] = {'/', '/api_server_full' }
FILTERS.Whitelist['uri_full'] = {}

-- URI Prefixes filter
-- will filter requests where the uri starts with any of the list below.
-- example:
-- filter: example.com/api_server_full?data=data
-- will not filter: example.com/full_api_server?data=data
-- FILTERS.Whitelist['uri_prefixes'] = {'/api_server'}
FILTERS.Whitelist['uri_prefixes'] = {'/report', '/portal', '/createKey', '/backoffice', '/oauth' }

-- IP Addresses filter
-- will filter requests coming from the ip in the list below
-- FILTERS.Whitelist['ip_addresses'] = {'192.168.99.1'}
FILTERS.Whitelist['ip_addresses'] = {}

-- Full useragent
-- will filter requests coming with a full user agent
--FILTERS.Whitelist['ua_full'] = {'Mozilla/5.0 (compatible; pingbot/2.0;  http://www.pingdom.com/)'}
FILTERS.Whitelist['ua_full'] = {'Mozilla/5.0 (compatible; pingbot/2.0;  http://www.pingdom.com/)'}

-- filter by user agent substring
--FILTERS.Whitelist['ua_sub'] = {'Inspectlet', 'GoogleCloudMonitoring'}
FILTERS.Whitelist['ua_sub'] = {'Inspectlet', 'GoogleCloudMonitoring'}

return FILTERS
