local RunService = game:GetService("RunService")

local serdeLayer = require(script.serdeLayer)
local ServerBridge = require(script.ServerBridge)
local ClientBridge = require(script.ClientBridge)
local rateManager = require(script.rateManager)

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

--[=[
	@function CreateBridgesFromDictionary
	@within BridgeNet
	
	Loops through the dictionary given and creates ``Bridge``s for the dictionary keys.
	Example usage:
	```lua
	local Network = BridgeNet.CreateBridgesFromDictionary({
		RemoteA = "RemoteA",
		RemoteB = "Rem_B", -- Creates bridge "Rem_B" with index "RemoteB"
		OtherRemotes = {
			PrintStuff = "Print",
			DoStuff = "DoStuff",
		},
	})
	```
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
local PrintRemotes = require(script.ConfigSymbols.PrintRemotes)
local SendLogFunction = require(script.ConfigSymbols.SendLogFunction)
local ReceiveLogFunction = require(script.ConfigSymbols.ReceiveLogFunction)
local Signal = require(script.Parent.GoodSignal)

local Started = Signal.new()

script.Destroying:Connect(function()
	serdeLayer._destroy()
	if isServer then
		ServerBridge._destroy()
	end
end)

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

	Started = Started,

	SendLogFunction = SendLogFunction,
	ReceiveLogFunction = ReceiveLogFunction,

	DefaultReceive = DefaultReceive,
	DefaultSend = DefaultSend,

	WaitForBridge = function(str)
		if not hasStarted then
			repeat
				task.wait()
			until hasStarted
		end
		if isServer then
			return ServerBridge.waitForBridge(str) :: ServerBridge.ServerObject
		else
			return ClientBridge.waitForBridge(str) :: ClientBridge.ClientObject
		end
	end,
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
	CreateBridgesFromDictionary = function(tbl: { [any]: string | {} })
		if not hasStarted then
			repeat
				task.wait()
			until hasStarted
		end
		local new
		if isServer then
			new = ServerBridge.new :: ServerBridge.ServerObject
		else
			new = ClientBridge.new :: ClientBridge.ClientObject
		end
		local function recursivelyAdd(tableTo: { [any]: string })
			local toReturn = {}
			for k, v in pairs(tableTo) do
				if typeof(v) ~= "table" then
					toReturn[k] = new(v)
				else
					toReturn[k] = recursivelyAdd(v)
				end
			end
			return toReturn
		end

		return recursivelyAdd(tbl) :: {
			[string]: ServerBridge.ServerObject | ClientBridge.ClientObject,
		}
	end,
	CreateIdentifiersFromDictionary = function(tbl: { [any]: string | {} })
		if not hasStarted then
			repeat
				task.wait()
			until hasStarted
		end

		local new
		if isServer then
			new = serdeLayer.CreateIdentifier
		else
			new = serdeLayer.WhatIsThis
		end
		local function recursivelyAdd(tableTo: { [any]: string })
			local toReturn = {}
			for k, v in pairs(tableTo) do
				if typeof(v) ~= "table" then
					toReturn[k] = new(v)
				else
					toReturn[k] = recursivelyAdd(v)
				end
			end
			return toReturn
		end

		return recursivelyAdd(tbl) :: {
			[string]: string | { [string]: string },
		}
	end,
	Start = function(config: { [any]: number | () -> any })
		local prefix = if RunService:IsServer() then "SERVER" else "CLIENT"

		if hasStarted then
			error(string.format("BridgeNet has already been started on the %s", prefix))
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
			print_remotes = config[PrintRemotes],
			send_function = config[SendLogFunction],
			receive_function = config[ReceiveLogFunction],
		}

		serdeLayer._start()
		Started:Fire()
		if isServer then
			return ServerBridge._start(configToSend)
		else
			return ClientBridge._start(configToSend)
		end
	end,
}
