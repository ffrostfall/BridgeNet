local RunService = game:GetService("RunService")

local DefaultReceive = require(script.Parent.ConfigSymbols.DefaultReceive)
local DefaultSend = require(script.Parent.ConfigSymbols.DefaultSend)
local SendLogFunction = require(script.Parent.ConfigSymbols.SendLogFunction)
local ReceiveLogFunction = require(script.Parent.ConfigSymbols.ReceiveLogFunction)

local SerdesLayer = require(script.Parent.SerdesLayer)
local ServerBridge = require(script.Parent.ServerBridge)
local ClientBridge = require(script.Parent.ClientBridge)

local hasStarted = false
local isServer = RunService:IsServer()

return function(config: { [any]: number | () -> any })
	local prefix = if RunService:IsServer() then "SERVER" else "CLIENT"

	if hasStarted then
		warn(string.format("BridgeNet has already been started on the %s", prefix))
		return false
	end
	hasStarted = true

	if not config[DefaultReceive] then
		warn(string.format("[%s] DefaultReceive doesn't exist!", prefix))
	end
	if not config[DefaultSend] then
		warn(string.format("[%s] DefaultSend doesn't exist!", prefix))
	end

	local configToSend = {
		send_default_rate = config[DefaultSend] or 60,
		receive_default_rate = config[DefaultReceive] or 60,
		send_function = config[SendLogFunction],
		receive_function = config[ReceiveLogFunction],
	}

	SerdesLayer._start()
	if isServer then
		ServerBridge._start(configToSend)
		return true
	else
		ClientBridge._start(configToSend)
		return true
	end
end
