local function getLuaVersion()
	local major, minor = _VERSION:match("Lua (%d)%.(%d)")
	local major, minor = tonumber(major), tonumber(minor)

	return major, minor
end

return {
	getLuaVersion = getLuaVersion,
}
