--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SerdesLayer = require(script.Parent.SerdesLayer)

type sendPacketQueue = { remote: string, args: { any }, requestType: string, replRate: number, uuid: string? }
type receivePacketQueue = { remote: string, args: { any } }

local RemoteEvent: RemoteEvent
local Invoke: string
local InvokeReply: string
local SendQueue: { sendPacketQueue } = {}
local ReceiveQueue: { receivePacketQueue } = {}
local BridgeObjects = {}
local threads: { thread? } = {}
local freeThread = nil

local FromCompressed = SerdesLayer.FromCompressed

local function functionPasser(fn, ...)
	fn(...)
end

local function yielder()
	while true do
		functionPasser(coroutine.yield())
	end
end

local function maybeSpawn(fn, ...)
	if not freeThread then
		freeThread = coroutine.create(yielder)
		coroutine.resume(freeThread)
	end
	local acquiredThread = freeThread
	freeThread = nil
	task.spawn(acquiredThread, fn, ...)
	freeThread = acquiredThread
end

--[=[
	@class ClientBridge
	
	Client-sided object for handling networking.
]=]
local ClientBridge = {}
ClientBridge.__index = ClientBridge

local function Connection(obj, v, callback)
	local result
	for _, func in obj._inboundMiddleware do
		if result then
			local potential = { func(table.unpack(result)) }
			if potential[1] == nil then
				return
			end
			result = potential
		else
			result = { func(table.unpack(v.args)) }
		end
	end

	result = result or v.args

	callback(table.unpack(result))
end

local function ConnectionWithNil(obj, v, callback, argCount)
	local result
	for _, func in obj._inboundMiddleware do
		if result then
			local potential = { func(table.unpack(result), 1, argCount) }
			if potential[1] == nil then
				return
			end
			result = potential
		else
			result = { func(table.unpack(v.args, 1, argCount)) }
		end
	end

	result = result or v.args

	callback(table.unpack(result))
end

local function ConnectionWithoutMiddleware(callback, args)
	callback(table.unpack(args))
end

local function ConnectionWithoutMiddlewareWithNil(callback, args, argCount)
	callback(table.unpack(args), 1, argCount)
end

--[=[
	Starts the internal processes for ClientBridge.
	
	@ignore
]=]
function ClientBridge._start()
	RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")

	Invoke = SerdesLayer.FromIdentifier("Invoke")
	InvokeReply = SerdesLayer.FromIdentifier("InvokeReply")

	local passingReplRates = {}

	RunService.Heartbeat:Connect(function()
		debug.profilebegin("ClientBridge")
		local currentTime = os.clock()

		debug.profilebegin("HandleReceive")
		for _, v in ReceiveQueue do
			local obj = BridgeObjects[FromCompressed(v.remote)]
			if not obj then
				continue
			end

			local args = v.args
			local allowsNil = obj._allowsNil

			if allowsNil then
				for i = 1, #args do
					if args[i] == SerdesLayer.NilIdentifier then
						args[i] = nil
					end
				end
			end

			if args[1] == InvokeReply then
				local argCount = #args
				local uuid = SerdesLayer.UnpackUUID(args[2])
				table.remove(args, 1)
				table.remove(args, 1)
				argCount -= 2
				task.spawn(threads[uuid], table.unpack(args, 1, argCount))
				threads[uuid] = nil -- don't want a memory leak ;)
				continue
			end

			if #obj._inboundMiddleware == 0 then
				if allowsNil then
					for _, callback in obj._connections do
						maybeSpawn(Connection, obj, args, callback)
					end
				else
					for _, callback in obj._connections do
						maybeSpawn(ConnectionWithNil, obj, args, callback, #args)
					end
				end
			else
				if allowsNil then
					for _, callback in obj._connections do
						maybeSpawn(ConnectionWithoutMiddleware, callback, args)
					end
				else
					for _, callback in obj._connections do
						maybeSpawn(ConnectionWithoutMiddlewareWithNil, callback, args, #args)
					end
				end
			end
		end
		table.clear(ReceiveQueue)
		debug.profileend()

		debug.profilebegin("HandleSend")
		local toSend = {}
		local replTicks = {}
		local remainingQueue = {}

		for i, v in remainingQueue do
			if (currentTime - replTicks[v.replRate]) <= (1 / v.replRate - 0.003) then
				table.insert(SendQueue, v)
				continue
			else
				table.remove(remainingQueue, i)
			end
		end

		for _, v: sendPacketQueue in SendQueue do
			if replTicks[v.replRate] then
				-- subtract 0.003 to make sure we don't accidentally skip any frames due to rounding errors
				if (currentTime - replTicks[v.replRate]) <= (1 / v.replRate - 0.003) then
					passingReplRates[v.replRate] = true
					if not passingReplRates[v.replRate] then
						table.insert(remainingQueue, v)
						continue
					end
				end
			end

			replTicks[v.replRate] = currentTime

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
				local bridgeObj = BridgeObjects[FromCompressed(v.remote)]

				if not (#bridgeObj._outboundMiddleware == 0) then
					local result
					for _, func in bridgeObj._outboundMiddleware do
						if result then
							local potential = { func(table.unpack(result)) }
							if #potential == 0 then
								continue
							end
							result = potential
						else
							result = { func(table.unpack(v.args)) }
						end
					end

					if result == nil then
						result = v.args
					end

					for _, k in result do
						table.insert(tbl, k)
					end
				else
					for _, k in v.args do
						table.insert(tbl, k)
					end
				end

				table.insert(toSend, tbl)
			end
		end

		if #toSend ~= 0 then
			RemoteEvent:FireServer(toSend)
		end
		SendQueue = remainingQueue
		debug.profileend()

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
	assert(type(remoteName) == "string", "[BridgeNet] remote name must be a string")

	local found = ClientBridge.from(remoteName)
	if found ~= nil then
		return found
	end

	local self = setmetatable({}, ClientBridge)

	self._name = remoteName
	self._connections = {}

	self._replRate = 60

	self._inboundMiddleware = {}
	self._outboundMiddleware = {}

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

function ClientBridge._returnQueue()
	return SendQueue, ReceiveQueue
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
		uuid = SerdesLayer.PackUUID(uuid),
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
	local stashedRef = func

	local disconnect = function()
		table.remove(self._connections, table.find(self._connections, stashedRef))
	end

	return disconnect
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
	assert(typeof(func) == "function", "[BridgeNet] :once() requires a function to be passed through")
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		func(...)
	end)
end

--[=[
	Sets the rate of which the Bridge sends and receives data.
	
	@param replRate number
	@return nil
]=]
function ClientBridge:SetReplicationRate(replRate: number)
	assert(typeof(replRate) == "number", "[BridgeNet] replication rate must be a number")
	self._replRate = replRate
end

--[=[
	Sets the Bridge's outbound middleware functions. Any function which returns nil will drop the sequence completely. Overrides existing middleware.
	
	A more comprehensive guide on middleware will be coming soon.
	```lua
	Object:SetOutboundMiddleware({
		function(plr, ...) -- Called first
			return ...
		end,
		function(plr, ...) -- Called second
			print("1")
			return ...
		end,
		function(plr, ...) -- Called third
			print("2")
			return ...
		end,
	})
	```
	
	@param middlewareTable { (...any) -> nil }
	@return nil
]=]
function ClientBridge:SetOutboundMiddleware(middlewareTbl: { (plr: Player, ...any) -> ...any })
	assert(typeof(middlewareTbl) == "table", "[BridgeNet] outbound middleware must be a table")
	self._outboundMiddleware = middlewareTbl
end

--[=[
	Sets the Bridge's inbound middleware functions. Any function which returns nil will drop the remote request completely. Overrides existing middleware.
	
	Allows you to change arguments or drop remote calls.
	
	A more comprehensive guide on middleware will be coming soon.
	```lua
	Object:SetInboundMiddleware({
		function(...) -- Called first
			return ...
		end,
		function(...) -- Called second
			print("1")
			return ...
		end,
		function(...) -- Called third
			print("2")
			return ...
		end,
	})
	```
	
	@param middlewareTable { (...any) -> nil }
	@return nil
]=]
function ClientBridge:SetInboundMiddleware(middlewareTbl: { (plr: Player, ...any) -> ...any })
	assert(typeof(middlewareTbl) == "table", "[BridgeNet] inbound middleware must be a table")
	self._inboundMiddleware = middlewareTbl
end

--[=[
	Allows nil parameters to be passed through without any weirdness. Does have a performance cost- this is off by default.
	
	@param allowed boolean
	@return nil
]=]
function ClientBridge:SetNilAllowed(allowed: boolean)
	assert(typeof(allowed) == "boolean", "[BridgeNet] cannot set nilAllowed to a non-bool")
	self._nilAllowed = allowed
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
	for k, v in self do
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
