local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local serdeLayer = require(script.Parent.serdeLayer)
local rateManager = require(script.Parent.rateManager)

local RemoteEvent

type sendPacketQueue = { remote: string, args: { any } }

type receivePacketQueue = { remote: string, args: { any } }

local SendQueue: { sendPacketQueue } = {}
local ReceiveQueue: { receivePacketQueue } = {}

local BridgeObjects = {}

--[=[
	@class ClientBridge
	
	Client-sided object for handling networking. Since it's on the client, all it really handles is queueing.
]=]
local ClientBridge = {}
ClientBridge.__index = ClientBridge

--[=[
	Starts the internal processes for ClientBridge.
	
	@param config dictionary
	@ignore
]=]
function ClientBridge._start(config)
	RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
	local lastSend = 0
	local lastReceive = 0
	RunService.Heartbeat:Connect(function()
		debug.profilebegin("ClientBridge")

		if (os.clock() - lastSend) > rateManager.GetSendRate() then
			local toSend = {}
			for _, v in pairs(SendQueue) do
				local value: sendPacketQueue = {
					v.remote,
					v.args,
				}
				table.insert(toSend, value)
			end
			RemoteEvent:FireServer(toSend)
			SendQueue = {}
		end

		if (os.clock() - lastReceive) > rateManager.GetReceiveRate() then
			for _, v in pairs(ReceiveQueue) do
				for _, k in pairs(BridgeObjects[serdeLayer.WhatIsThis(v.remote, "id")]._connections) do
					k(table.unpack(v.args))
				end
			end
			ReceiveQueue = {}
		end

		debug.profileend()
	end)

	RemoteEvent.OnClientEvent:Connect(function(tbl)
		for _, v in pairs(tbl) do
			table.insert(ReceiveQueue, {
				remote = v[1],
				args = v[2],
			})
		end
	end)
end

function ClientBridge.new(remoteName: string)
	local self = setmetatable({}, ClientBridge)

	self._name = remoteName
	self._connections = {}

	self._id = serdeLayer.WhatIsThis(self._name, "compressed")

	BridgeObjects[self._name] = self
	return self
end

--[=[
	The equivelant of :FireServer().
	
	```lua
	local Bridge = ClientBridge.new("Remote")
	
	Bridge:Fire("Hello", "world!")
	```
	
	@param ... any
]=]
function ClientBridge:Fire(...: any)
	table.insert(SendQueue, {
		remote = self._id,
		args = table.pack(...),
	})
end

--[=[
	Creates a connection. Can be disconnected using :Disconnect().
	
	```lua
	local Bridge = ClientBridge.new("Remote")
	
	Bridge:Connect(function(text)
		print(text)
	end)
	```
	
	@param func function
]=]
function ClientBridge:Connect(func: (...any) -> nil)
	local index = table.insert(self._connections, func)
	return {
		Disconnect = function()
			table.remove(self._connections, index)
		end,
	}
end

--[=[
	Destroys the ClientBridge object. Doesn't destroy the RemoteEvent, or destroy the identifier. It doesn't send anything to the server. Just destroys the client sided object.
	
	```lua
	local Bridge = ClientBridge.new("Remote")
	
	ClientBridge:Destroy()
	
	ClientBridge:Fire() -- Errors
	```
]=]
function ClientBridge:Destroy()
	BridgeObjects[self._name] = nil
	for k, v in pairs(self) do
		if v.Destroy ~= nil then
			v:Destroy()
		else
			self[k] = nil
		end
	end
	setmetatable(self, nil)
end

return ClientBridge
