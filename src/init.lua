local RunService = game:GetService("RunService")

local SerdesLayer = require(script.SerdesLayer)
local ServerBridge = require(script.ServerBridge)
local ClientBridge = require(script.ClientBridge)
local CreateBridgeTree = require(script.CreateBridgeTree)
local Bridge = require(script.Bridge)

local isServer = RunService:IsServer()

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

export type ServerBridge = ServerBridge.ServerObject
export type ClientBridge = ClientBridge.ClientObject

export type Bridge = ServerBridge | ClientBridge

script.Destroying:Connect(function()
	SerdesLayer._destroy()
	if isServer then
		ServerBridge._destroy()
	end
end)

SerdesLayer._start()
if isServer then
	ServerBridge._start()
else
	ClientBridge._start()
end

return {
	CreateBridgeTree = CreateBridgeTree,
	Bridge = Bridge,

	Identifiers = function(tbl: { string })
		local ReturnValue = {}

		for _, v in tbl do
			ReturnValue[v] = SerdesLayer.CreateIdentifier(v)
		end

		return ReturnValue :: { [string]: string }
	end,

	CreateIdentifier = SerdesLayer.CreateIdentifier,
	DestroyIdentifier = SerdesLayer.DestroyIdentifier,

	CreateUUID = SerdesLayer.CreateUUID,
	PackUUID = SerdesLayer.PackUUID,
	UnpackUUID = SerdesLayer.UnpackUUID,

	DictionaryToTable = SerdesLayer.DictionaryToTable,

	--[[LogNetTraffic = function(duration: number)
		if isServer then
			return ServerBridge._log(duration)
		else
			return ClientBridge._log(duration)
		end
	end,]]

	ReplicationStep = function(rate: number, func: () -> nil)
		if isServer then
			return ServerBridge._getReplicationStepSignal(rate, func)
		else
			return ClientBridge._getReplicationStepSignal(rate, func)
		end
	end,

	GetQueue = function()
		if isServer then
			local send, receive = ServerBridge._returnQueue()
			return send, receive
		else
			local send, receive = ClientBridge._returnQueue()
			return send, receive
		end
	end,

	CreateBridge = function(str)
		if isServer then
			return ServerBridge.new(str)
		else
			return ClientBridge.new(str)
		end
	end,
}
