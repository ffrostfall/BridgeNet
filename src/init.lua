local RunService = game:GetService("RunService")

local serdeLayer = require(script.serdeLayer)
local ServerBridge = require(script.ServerBridge)
local ClientBridge = require(script.ClientBridge)
local rateManager = require(script.rateManager)

local isServer = RunService:IsServer()

export type config = {
	send_default_rate: number,
	receive_default_rate: number,
}

--[=[
	@class BridgeNet
	
	The interface for the package.
]=]

--[=[
	@function CreateBridge
	@within BridgeNet
	
	Creates a ServerBridge or a ClientBridge depending on if it's the server or client calling.
	
	```lua
	local Bridge = BridgeNet.CreateBridge("Remote")
	```
	
	@param remoteName string
	@return ServerBridge | ClientBridge
]=]

--[=[
	@function FromBridge
	@within BridgeNet
	
	Fetches a ServerBridge or ClientBridge from the string provided.
	
	```lua
	local Bridge = BridgeNet.FromBridge("Remote")
	```
	
	@param remoteName string
	@return ServerBridge | ClientBridge | nil
]=]
return {
	CreateIdentifier = serdeLayer.CreateIdentifier,
	WhatIsThis = serdeLayer.WhatIsThis,
	DestroyIdentifier = serdeLayer.DestroyIdentifier,

	SetSendRate = rateManager.SetSendRate,
	GetSendRate = rateManager.GetSendRate,
	SetReceiveRate = rateManager.SetReceiveRate,
	GetReceiveRate = rateManager.GetReceiveRate,

	FromBridge = function(str)
		if isServer then
			return ServerBridge.from(str)
		else
			return ClientBridge.from(str)
		end
	end,
	CreateBridge = function(str)
		if isServer then
			return ServerBridge.new(str)
		else
			return ClientBridge.new(str)
		end
	end,
	Start = function(config: config)
		local serverOrClientText = if isServer then "[SERVER]" else "[CLIENT]"
		if config["default_receive_rate"] then
			error(("[%s] Did you mean receive_default_rate?"):format(serverOrClientText))
		end
		if config["default_send_rate"] then
			error(("[%s] Did you mean send_default_rate?"):format(serverOrClientText))
		end
		assert(
			config["receive_default_rate"],
			("[%s] receive_default_rate is nil in config"):format(serverOrClientText)
		)
		assert(config["send_default_rate"], ("[%s] send_default_rate is nil in config"):format(serverOrClientText))

		serdeLayer._start()
		if isServer then
			return ServerBridge._start(config)
		else
			return ClientBridge._start(config)
		end
	end,
}
