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

local activeConfig

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
	activeConfig = config

	RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")

	rateManager.SetSendRate(config.send_default_rate)
	rateManager.SetReceiveRate(config.receive_default_rate)

	local sendDelta = 0
	local receiveDelta = 0
	RunService.Heartbeat:Connect(function(delta)
		sendDelta += delta
		receiveDelta += delta
		
		debug.profilebegin("ClientBridge")

		if sendDelta > rateManager.GetSendRate() then
			sendDelta = 0
			local SendQueueLength = #SendQueue
			local toSend = table.create(SendQueueLength)
			for _, v in ipairs(SendQueue) do
				local tbl = table.create(#v.args + 1)
				tbl[1] = v.remote
				for _, k in ipairs(v.args) do
					table.insert(tbl, k)
				end

				if activeConfig.receive_function ~= nil then
					activeConfig.receive_function(serdeLayer.WhatIsThis(v.remote, "id"), unpack(v.args))
				end

				table.insert(toSend, tbl)
			end
			if SendQueueLength ~= 0 then
				RemoteEvent:FireServer(toSend)
			end
			table.clear(SendQueue)
		end

		if receiveDelta > rateManager.GetReceiveRate() then
			receiveDelta = 0
			for _, v in ipairs(ReceiveQueue) do
				local remoteName = serdeLayer.WhatIsThis(v.remote, "id")
				if BridgeObjects[remoteName] == nil then
					continue
					--error("[BridgeNet] Client received non-existant Bridge. Naming mismatch?")
				end
				for callback, timesConnected in pairs(BridgeObjects[remoteName]._connections) do
					for _ = 1, timesConnected do
						task.spawn(callback, unpack(v.args))
						if activeConfig.receive_function ~= nil then
							task.spawn(activeConfig.receive_function, remoteName, unpack(v.args))
						end
					end
				end
			end
			table.clear(ReceiveQueue)
		end

		debug.profileend()
	end)

	RemoteEvent.OnClientEvent:Connect(function(tbl)
		for _, params in ipairs(tbl) do
			local remote = params[1]
			table.remove(params, 1)
			print(params)
			table.insert(ReceiveQueue, {
				remote = remote,
				args = params,
			})
		end
	end)
end

function ClientBridge.new(remoteName: string)
	assert(type(remoteName) == "string", "[BridgeNet] Remote name must be a string")

	local found = ClientBridge.from(remoteName)
	if found ~= nil then
		return found
	end

	local self = setmetatable({}, ClientBridge)

	self._name = remoteName
	self._connections = {}

	self._id = serdeLayer.WhatIsThis(self._name, "compressed")
	if self._id == nil then
		task.spawn(function()
			local timer = 0
			repeat
				timer += task.wait()
				self._id = serdeLayer.WhatIsThis(self._name, "compressed")
			until self._id ~= nil or timer >= 10
		end)
	end

	BridgeObjects[self._name] = self
	return self
end

function ClientBridge.from(remoteName: string)
	assert(type(remoteName) == "string", "[BridgeNet] Remote name must be a string")
	return BridgeObjects[remoteName]
end

function ClientBridge.waitForBridge(remoteName: string)
	while true do
		local bridge = BridgeObjects[remoteName]
		if bridge then
			return bridge
		end
		task.wait()
	end
end

--[=[
	The equivalent of :FireServer().
	
	```lua
	local Bridge = ClientBridge.new("Remote")
	
	Bridge:Fire("Hello", "world!")
	```
	
	@param ... any
]=]
function ClientBridge:Fire(...: any)
	if self._id == nil then
		self._id = serdeLayer.WhatIsThis(self._name, "compressed")
	end
	table.insert(SendQueue, {
		remote = self._id,
		args = { ... },
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
	@return nil
]=]
function ClientBridge:Connect(func: (...any) -> nil)
	assert(type(func) == "function", "[BridgeNet] Attempt to connect non-function to a Bridge")
	if self._connections[func] then
		self._connections[func] += 1
	else
		self._connections[func] = 1
	end

	local connection
	connection = {
		Disconnect = function()
			if connection.Connected then
				connection.Connected = false
				self._connections[func] -= 1
				if 1 > self._connections[func] then
					self._connections[func] = nil
				end
			end
		end,
		Connected = true
	}

	return connection
end

--[[
	Creates a connection, when fired it will disconnect.
	
	```lua
	local Bridge = ClientBridge.new("ConstantlyFiringText")
	
	Bridge:Connect(function(text)
		print(text) -- Fires multiple times
	end)
	
	Bridge:Once(function(text)
		print(text) -- Fires once
	end)
	```
	
	@param func function
	@return nil
function ClientBridge:Once(func: (...any) -> nil)
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		func(...)
	end)
end
]]

--[=[
	Destroys the ClientBridge object. Doesn't destroy the RemoteEvent, or destroy the identifier. It doesn't send anything to the server. Just destroys the client sided object.
	
	```lua
	local Bridge = ClientBridge.new("Remote")
	
	ClientBridge:Destroy()
	
	ClientBridge:Fire() -- Errors
	```
	
	@return nil
]=]
function ClientBridge:Destroy()
	BridgeObjects[self._name] = nil
	for k, v in ipairs(self) do
		if v.Destroy ~= nil then
			v:Destroy()
		else
			self[k] = nil
		end
	end
	setmetatable(self, nil)
end

return ClientBridge
