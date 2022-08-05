local RunService = game:GetService("RunService")

local serdeLayer = require(script.serdeLayer)
local ServerBridge = require(script.ServerBridge)
local ClientBridge = require(script.ClientBridge)
local rateManager = require(script.rateManager)

local isServer = RunService:IsServer()

export type config = {
	send_default_rate: number,
	receive_default_rate: number,
	--one_remote_event: boolean, TODO This is W.I.P. Right now there's no support for it
}

--[=[
	@class Network
	
	The interface for the package.
]=]

--[=[
	@function CreateBridge
	@within Network
	
	Creates a ServerBridge or a ClientBridge depending on if it's the server or client calling.
	
	```lua
	local Bridge = Network.CreateBridge("Remote")
	```
	
	@param remoteName string
	@return ServerBridge | ClientBridge
]=]
return {
	CreateIdentifier = serdeLayer.CreateIdentifier,
	WhatIsThis = serdeLayer.WhatIsThis,
	DestroyIdentifier = serdeLayer.DestroyIdentifier,
	SetSendRate = rateManager.SetSendRate,
	GetSendRate = rateManager.GetSendRate,
	SetReceiveRate = rateManager.SetReceiveRate,
	GetReceiveRate = rateManager.GetReceiveRate,

	CreateBridge = function(str)
		if isServer then
			return ServerBridge.new(str)
		else
			return ClientBridge.new(str)
		end
	end,
	Start = function(config: config)
		if isServer then
			return ServerBridge._start(config)
		else
			return ClientBridge._start(config)
		end
	end,
}
