type config = {
	maxRatePerMinute: number,
	Middleware: { (...any) -> ...any },
}

return function(name: string, config: config)
	return {
		_isBridge = true,
		middleware = config.Middleware,
		rate = config.maxRatePerMinute,
		name = name,
	}
end
