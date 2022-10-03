type config = {
	ReplicationRate: number?,
	NilAllowed: boolean,
	Server: {
		InboundMiddleware: { (...any) -> ...any }?,
		OutboundMiddleware: { (...any) -> ...any }?,
	}?,
	Client: {
		InboundMiddleware: { (...any) -> ...any }?,
		OutboundMiddleware: { (...any) -> ...any }?,
	}?,
}

return function(config: config?)
	if config == nil then
		return { _isBridge = true }
	end
	return {
		_isBridge = true,
		server = config["Server"],
		client = config["Client"],
		replicationrate = config["ReplicationRate"],
		allowsnil = config["NilAllowed"],
	}
end
