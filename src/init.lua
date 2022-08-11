local RunService = game:GetService("RunService")

local serdeLayer = require(script.serdeLayer)
local ServerBridge = require(script.ServerBridge)
local ClientBridge = require(script.ClientBridge)
local rateManager = require(script.rateManager)
local Symbol = require(script.Symbol)

local isServer = RunService:IsServer()

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
	@function WaitForBridge
	@within BridgeNet	

	Waits for a BridgeObject to be created, then resumes the thread.
	This does NOT replicate. If the server creates a BridgeObject, it will NOT replicate to the client.
	This will wait until a BridgeObject is created for the client/server respectively.
	
	```lua
	print("client is waiting for the bridge to be created on the client..")
	local Bridge = BridgeNet.WaitForBridge("Remote")
	print("client is done waiting! was created in another script.")
	```
	
	@return BridgeObject
]=]

local DefaultReceive = Symbol.named("DefaultReceive")
local DefaultSend = Symbol.named("DefaultSend")
local PrintRemotes = Symbol.named("PrintRemotes")
local SendLogFunction = Symbol.named("SendLogFunction")
local ReceiveLogFunction = Symbol.named("ReceiveLogFunction")

return {
	CreateIdentifier = serdeLayer.CreateIdentifier,
	WhatIsThis = serdeLayer.WhatIsThis,
	DestroyIdentifier = serdeLayer.DestroyIdentifier,

	SetSendRate = rateManager.SetSendRate,
	GetSendRate = rateManager.GetSendRate,
	SetReceiveRate = rateManager.SetReceiveRate,
	GetReceiveRate = rateManager.GetReceiveRate,

	CreateUUID = serdeLayer.CreateUUID,
	PackUUID = serdeLayer.PackUUID,
	UnpackUUID = serdeLayer.UnpackUUID,

	DictionaryToTable = serdeLayer.DictionaryToTable,

	SendLogFunction = SendLogFunction,
	ReceiveLogFunction = ReceiveLogFunction,

	DefaultReceive = DefaultReceive,
	DefaultSend = DefaultSend,

	WaitForBridge = function(str)
		if isServer then
			return ServerBridge.waitForBridge(str)
		else
			return ClientBridge.waitForBridge(str)
		end
	end,
	CreateBridge = function(str)
		if isServer then
			return ServerBridge.new(str)
		else
			return ClientBridge.new(str)
		end
	end,
	Start = function(config: { [any]: number })
		local prefix = if RunService:IsServer() then "SERVER" else "CLIENT"
		if not config[DefaultReceive] then
			warn(("[%s] DefaultReceive doesn't exist!"):format(prefix))
		end
		if not config[DefaultSend] then
			warn(("[%s] DefaultSend doesn't exist!"):format(prefix))
		end

		local configToSend = {
			send_default_rate = config[DefaultSend],
			receive_default_rate = config[DefaultReceive],
			print_remotes = config[PrintRemotes],
			send_function = config[SendLogFunction],
			receive_function = config[ReceiveLogFunction],
		}

		serdeLayer._start()
		if isServer then
			return ServerBridge._start(configToSend)
		else
			return ClientBridge._start(configToSend)
		end
	end,
}
