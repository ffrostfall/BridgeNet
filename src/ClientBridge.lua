local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent.Promise)
local serdeLayer = require(script.Parent.serdeLayer)
local rateManager = require(script.Parent.rateManager)

local RemoteEvent
local Invoke
local InvokeReply

type sendPacketQueue = { remote: string, args: { any }, requestType: string, uuid: string? }

type receivePacketQueue = { remote: string, args: { any } }

local SendQueue: { sendPacketQueue } = {}
local ReceiveQueue: { receivePacketQueue } = {}

local BridgeObjects = {}

local activeConfig

local threads = {}

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

	Invoke = serdeLayer.WhatIsThis("Invoke", "compressed")
	InvokeReply = serdeLayer.WhatIsThis("InvokeReply", "compressed")
	print(Invoke)
	print(InvokeReply)
	local lastSend = 0
	local lastReceive = 0
	RunService.Heartbeat:Connect(function()
		debug.profilebegin("ClientBridge")

		if (time() - lastSend) > rateManager.GetSendRate() then
			local toSend = {}
			for _, v in ipairs(SendQueue) do
				if v.requestType == "invoke" then
					local tbl = {}
					table.insert(tbl, v.remote)
					table.insert(tbl, Invoke)
					table.insert(tbl, v.uuid)
					for _, k in ipairs(v.args) do
						table.insert(tbl, k)
					end
					table.insert(toSend, tbl)
				elseif v.requestType == "send" then
					local tbl = {}
					table.insert(tbl, v.remote)

					for _, k in ipairs(v.args) do
						table.insert(tbl, k)
					end

					if activeConfig.send_function ~= nil then
						activeConfig.send_function(serdeLayer.WhatIsThis(v.remote, "id"), unpack(v.args))
					end

					table.insert(toSend, tbl)
				end
			end
			if #toSend ~= 0 then
				RemoteEvent:FireServer(toSend)
			end
			SendQueue = {}
		end

		if (time() - lastReceive) > rateManager.GetReceiveRate() then
			for _, v in ipairs(ReceiveQueue) do
				local args = v.args
				local remoteName = serdeLayer.WhatIsThis(v.remote, "id")
				if BridgeObjects[remoteName] == nil then
					continue
					--error("[BridgeNet] Client received non-existant Bridge. Naming mismatch?")
				end
				if v.args[1] ~= InvokeReply then
					for callback, timesConnected in pairs(BridgeObjects[remoteName]._connections) do
						for _ = 1, timesConnected do
							task.spawn(callback, unpack(args))
							if activeConfig.receive_function ~= nil then
								task.spawn(activeConfig.receive_function, remoteName, unpack(args))
							end
						end
					end
				elseif args[1] == InvokeReply then
					local uuid = args[2]
					table.remove(args, 1)
					table.remove(args, 2)
					coroutine.resume(threads[uuid], unpack(args))
				end
			end
			ReceiveQueue = {}
		end

		debug.profileend()
	end)

	RemoteEvent.OnClientEvent:Connect(function(tbl)
		for _, v in ipairs(tbl) do
			local params = v
			local remote = params[1]
			table.remove(params, 1)
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
			local nextOutput = timer + 0.1
			repeat
				timer += task.wait()
				self._id = serdeLayer.WhatIsThis(self._name, "compressed")
				if timer > nextOutput then
					nextOutput += 0.1
					print("[BridgeNet] waiting for (" .. self._name .. ") to be replicated to the client")
				end
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
	repeat
		task.wait()
	until BridgeObjects[remoteName]
	return BridgeObjects[remoteName]
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
		requestType = "send",
		args = { ... },
	})
end

function ClientBridge:InvokeServerAsync(...: any)
	if self._id == nil then
		self._id = serdeLayer.WhatIsThis(self._name, "compressed")
	end

	local thread = coroutine.running()
	local uuid = serdeLayer.CreateUUID()

	threads[uuid] = thread

	table.insert(SendQueue, {
		remote = self._id,
		requestType = "invoke",
		uuid = uuid,
		args = { ... },
	})

	return coroutine.yield()
end

function ClientBridge:InvokeServer(...)
	local args = table.pack(...)
	return Promise.new(function(resolve)
		resolve(self:InvokeServerAsync(table.unpack(args))) -- weirdest hack i've ever done, but it errored if i didn't do this???
	end)
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
		Connected = true,
	}

	return connection
end

--[[
	Gets the ClientBridge's name.
	
	```lua
	local Bridge = ClientBridge.new("Remote")
	
	print(Bridge:GetName()) -- Prints "Remote"
	```
	
	@return string
]]
function ClientBridge:GetName()
	return self._name
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
