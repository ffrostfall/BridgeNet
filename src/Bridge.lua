type config = {
	maxRatePerMinute: number,
	Middleware: { (...any) -> ...any },
	Rate: number,
}

return function(config: config)
	return {
		_isBridge = true,
		middleware = config["Middleware"],
		rate = config["maxRatePerMinute"],
		sendreceiverate = config["Rate"],
	}
end
