local RunService = game:GetService("RunService")

local SendLogFunction = require(script.Parent.ConfigSymbols.SendLogFunction)
local ReceiveLogFunction = require(script.Parent.ConfigSymbols.ReceiveLogFunction)
local DefaultSend = require(script.Parent.ConfigSymbols.DefaultSend)

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

	local configToSend = {
		send_function = config[SendLogFunction],
		receive_function = config[ReceiveLogFunction],
		send_default_rate = config[DefaultSend],
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
