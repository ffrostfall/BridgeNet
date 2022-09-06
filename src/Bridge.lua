type config = {
	maxRatePerMinute: number,
	Middleware: { (...unknown) -> ...any },
	Rate: number,
}

return function(config: config?)
	if config == nil then
		return { _isBridge = true }
	end
	return {
		_isBridge = true,
		middleware = config["Middleware"],
		rate = config["maxRatePerMinute"],
		sendreceiverate = config["Rate"],
	}
end
