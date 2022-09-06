local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent.Promise)
local SerdesLayer = require(script.Parent.SerdesLayer)

local RemoteEvent: RemoteEvent
local Invoke: string
local InvokeReply: string

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

	Invoke = SerdesLayer.FromIdentifier("Invoke")
	InvokeReply = SerdesLayer.FromIdentifier("InvokeReply")

	RunService.Heartbeat:Connect(function()
		debug.profilebegin("ClientBridge")
		local currentTime = os.clock()

		local toSend = {}
		local replTicks = {}
		for _, v in SendQueue do
			if replTicks[v.replRate] then
				if not ((currentTime - replTicks[v.replRate]) <= 1 / v.replRate) then
					continue
				end
			else
				replTicks[v.replRate] = currentTime
			end

			for i = 1, #v.args do
				if v.args[i] == nil then
					v.args[i] = SerdesLayer.NilIdentifier
				end
			end

			if v.requestType == "invoke" then
				local tbl = { v.remote, Invoke, v.uuid }

				for _, k in v.args do
					table.insert(tbl, k)
				end

				table.insert(toSend, tbl)
			elseif v.requestType == "send" then
				local tbl = { v.remote }

				for _, k in v.args do
					table.insert(tbl, k)
				end

				if activeConfig.send_function ~= nil then
					activeConfig.send_function(SerdesLayer.FromCompressed(v.remote), unpack(v.args))
				end

				table.insert(toSend, tbl)
			end
		end
		if #toSend ~= 0 then
			RemoteEvent:FireServer(toSend)
		end
		SendQueue = {}

		for _, v in ReceiveQueue do
			local args = v.args
			local argCount = #args
			local remoteName = SerdesLayer.FromCompressed(v.remote)

			if BridgeObjects[remoteName] == nil then
				continue
				--error("[BridgeNet] Client received non-existant Bridge. Naming mismatch?")
			end

			for i = 1, #args do
				if args[i] == SerdesLayer.NilIdentifier then
					args[i] = nil
				end
			end

			if args[1] ~= InvokeReply then
				for callback, timesConnected in pairs(BridgeObjects[remoteName]._connections) do
					for _ = 1, timesConnected do
						task.spawn(callback, unpack(args, 1, argCount))
						if activeConfig.receive_function ~= nil then
							task.spawn(activeConfig.receive_function, remoteName, unpack(args, 1, argCount))
						end
					end
				end
			elseif args[1] == InvokeReply then
				local uuid = args[2]
				table.remove(args, 1)
				table.remove(args, 1)
				argCount -= 2
				task.spawn(threads[uuid], unpack(args, 1, argCount))
				threads[uuid] = nil -- don't want a memory leak ;)
			end
		end

		ReceiveQueue = {}

		debug.profileend()
	end)

	RemoteEvent.OnClientEvent:Connect(function(tbl)
		for _, v in tbl do
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

	self._replRate = 60

	self._id = SerdesLayer.FromIdentifier(self._name)
	if self._id == nil then
		task.spawn(function()
			local timer = 0
			local nextOutput = timer + 0.1
			repeat
				timer += task.wait()
				self._id = SerdesLayer.FromIdentifier(self._name)
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
	while not BridgeObjects[remoteName] do
		task.wait()
	end
	return BridgeObjects[remoteName]
end

--[=[
	The equivalent of :FireServer().
	
	```lua
	local Bridge = BridgeNet.CreateBridge("Remote")
	
	Bridge:Fire("Hello", "world!")
	```
	
	@param ... any
]=]
function ClientBridge:Fire(...: any)
	if self._id == nil then
		self._id = SerdesLayer.FromIdentifier(self._name)
	end
	table.insert(SendQueue, {
		remote = self._id,
		requestType = "send",
		args = { ... },
		replRate = self._replRate,
	})
end

--[=[
	Invokes the server for a response. Promise wrapper over :InvokeServerAsync()
	
	```lua
	local Bridge = BridgeNet.CreateBridge("Remote")
	
	local data = Bridge:InvokeServerAsync("whats 2+2?")
	print(data) -- prints "4"
	```
	
	@param ... any
	@return ...any
]=]
function ClientBridge:InvokeServerAsync(...: any)
	if self._id == nil then
		self._id = SerdesLayer.FromIdentifier(self._name)
	end

	local thread = coroutine.running()
	local uuid = SerdesLayer.CreateUUID()

	threads[uuid] = thread

	table.insert(SendQueue, {
		remote = self._id,
		requestType = "invoke",
		uuid = uuid,
		args = { ... },
		replRate = self._replRate,
	})

	local response = { coroutine.yield() }
	if response[1] == "err" then
		error(response[2], 2)
	end

	return table.unpack(response)
end

--[=[
	Invokes the server for a response. Promise wrapper over :InvokeServerAsync()
	
	```lua
	local Bridge = BridgeNet.CreateBridge("Remote")
	
	local data = Bridge:InvokeServer("this text will be returned but with something added at the end!"):andThen(function(string)
		print(string) -- Prints "this text will be returned but with something added at the end!something"
	end)
	```
	
	@param ... any
	@return Promise
]=]
function ClientBridge:InvokeServer(...: any)
	local args = table.pack(...)
	return Promise.new(function(resolve)
		resolve(self:InvokeServerAsync(table.unpack(args))) -- weirdest hack i've ever done, but it errored if i didn't do this???
	end)
end

--[=[
	Creates a connection. Can be disconnected using :Disconnect().
	
	```lua
	local Bridge = BridgeNet.CreateBridge("Remote")
	
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
	local Bridge = BridgeNet.CreateBridge("Remote")
	
	print(Bridge:GetName()) -- Prints "Remote"
	```
	
	@return string
]]
function ClientBridge:GetName()
	return self._name
end

--[=[
	Creates a connection, when fired it will disconnect.
	
	```lua
	local Bridge = BridgeNet.CreateBridge("ConstantlyFiringText")
	
	Bridge:Connect(function(text)
		print(text) -- Fires multiple times
	end)
	
	Bridge:Once(function(text)
		print(text) -- Fires once
	end)
	```
	
	@param func function
	@return nil
]=]
function ClientBridge:Once(func: (...any) -> nil)
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		func(...)
	end)
end

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
	for k, v in pairs(self) do
		if v.Destroy ~= nil then
			v:Destroy()
		else
			self[k] = nil
		end
	end
	setmetatable(self, nil)
end

export type ClientObject = typeof(ClientBridge.new(""))

return ClientBridge
