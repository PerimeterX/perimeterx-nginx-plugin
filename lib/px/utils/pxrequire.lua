local _M = {}

function _M.require(name)
	package.loaded[ name ] = nil
	return require (name)
end 

return _M