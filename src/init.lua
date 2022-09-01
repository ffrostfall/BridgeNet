local RunService = game:GetService("RunService")

local SerdesLayer = require(script.SerdesLayer)
local ServerBridge = require(script.ServerBridge)
local ClientBridge = require(script.ClientBridge)

local isServer = RunService:IsServer()
local hasStarted = false

type ClientBridgeDictionary = {
	[string]: ClientBridge.ClientObject,
}

type ServerBridgeDictionary = {
	[string]: ServerBridge.ServerObject,
}

--[=[
	@class BridgeNet
	
	The interface for the package.
]=]

--[=[
	@function CreateBridge
	@within BridgeNet
	
	Creates a ServerBridge or a ClientBridge depending on if it's the server or client calling. If a Bridge of that name already exists, it'll return that Bridge object.
	This can be used to fetch bridges, but .WaitForBridge is recommended.
	
	```lua
	local Bridge = BridgeNet.CreateBridge("Remote")
	```
	
	@param remoteName string
	@return ServerBridge | ClientBridge
]=]

--[=[
	@function Start
	@within BridgeNet
	
	This function starts BridgeNet. It must be called on both the client and server.
		
	All possible parameters:
		- DefaultReceive (BridgeNet.DefaultReceive) sets the rate of which incoming data is handled. Defaults to 60 hz
		- DefaultSend (BridgeNet.DefaultSend) sets the rate of which outgoing data is sent. Defaults to 60 hz
		- SendLogFunction (BridgeNet.SendLogFunction) sets the custom logging function for all outgoing data. Default is none [UNSTABLE]
		- ReceiveLogFunction (BridgeNet.ReceiveLogFunction) sets the custom logging function for all incoming data. Default is none [UNSTABLE]
	```lua
		BridgeNet.Start({ -- server
			[BridgeNet.DefaultReceive] = 60,
			[BridgeNet.DefaultSend] = 60,
			[SendLogFunction] = function(remote, plrs, ...) 
				local args = table.pack(...)
				print(remote, plrs, args)
			end,
			[ReceiveLogFunction] = function(remote, plr, ...)
				print(remote, plr, args)
			end,
		})
	```
	
	@param options {}
	@return nil
]=]

local DefaultReceive = require(script.ConfigSymbols.DefaultReceive)
local DefaultSend = require(script.ConfigSymbols.DefaultSend)
local SendLogFunction = require(script.ConfigSymbols.SendLogFunction)
local ReceiveLogFunction = require(script.ConfigSymbols.ReceiveLogFunction)
local Signal = require(script.Parent.GoodSignal)
local Declare = require(script.Declare)
local Start = require(script.Start)
local Identifiers = require(script.Identifiers)
local Bridge = require(script.Bridge)

local Started = Signal.new()

script.Destroying:Connect(function()
	SerdesLayer._destroy()
	if isServer then
		ServerBridge._destroy()
	end
end)

return {
	Declare = Declare,
	Bridge = Bridge,
	Identifiers = Identifiers,

	CreateIdentifier = SerdesLayer.CreateIdentifier,
	DestroyIdentifier = SerdesLayer.DestroyIdentifier,

	CreateUUID = SerdesLayer.CreateUUID,
	PackUUID = SerdesLayer.PackUUID,
	UnpackUUID = SerdesLayer.UnpackUUID,

	DictionaryToTable = SerdesLayer.DictionaryToTable,

	Started = Started,

	SendLogFunction = SendLogFunction,
	ReceiveLogFunction = ReceiveLogFunction,
	DefaultReceive = DefaultReceive,
	DefaultSend = DefaultSend,

	CreateBridge = function(str)
		if not hasStarted then
			repeat
				task.wait()
			until hasStarted
		end
		if isServer then
			return ServerBridge.new(str)
		else
			return ClientBridge.new(str)
		end
	end,
	Start = function(config: { [any]: number | () -> any })
		if Start(config) then
			Started:Fire()
			hasStarted = true
		end
	end,
}
