local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local serdeLayer = require(script.Parent.serdeLayer)
local rateManager = require(script.Parent.rateManager)

type queueSendPacket = { plrs: string | Player | { Player }, remote: string, args: { any } }

type queueReceivePacket = { plr: Player, remote: string, args: { any } }

type config = {
	send_default_rate: number,
	receive_default_rate: number,
	--one_remote_event: boolean,
}

type logEntry = {
	Remote: Player,
}

local SendQueue: { queueSendPacket } = {}
local ReceiveQueue: { queueReceivePacket } = {}

local BridgeObjects = {}

local lastSend: number = 0
local lastReceive: number = 0

local Invoke
local InvokeReply

local activeConfig

--[=[
	@class ServerBridge
	
	The general method of communicating from the server to the client.
]=]
local ServerBridge = {}
ServerBridge.__index = ServerBridge

--[=[
	Starts the internal processes for ServerBridge.
	
	@param config dictionary
	@ignore
]=]
function ServerBridge._start(config: config): nil
	activeConfig = config

	local RemoteEvent = Instance.new("RemoteEvent")
	RemoteEvent.Name = "RemoteEvent"
	RemoteEvent.Parent = ReplicatedStorage

	Invoke = serdeLayer.CreateIdentifier("Invoke")
	InvokeReply = serdeLayer.CreateIdentifier("InvokeReply")

	rateManager.SetSendRate(activeConfig.send_default_rate)
	rateManager.SetReceiveRate(activeConfig.receive_default_rate)

	RunService.Heartbeat:Connect(function()
		debug.profilebegin("ServerBridge")
		local sendRate = rateManager.GetSendRate()
		local receiveRate = rateManager.GetReceiveRate()

		--[[if (time() - lastClear) > 60 then
			lastClear = time()

			for _, v in ipairs(BridgeObjects) do
				v._rateInThisMinute = 0
			end
		end]]

		if (time() - lastSend) >= sendRate then
			lastSend = time()

			local toSendAll = {}
			local toSendPlayers = {}
			for _, v in ipairs(SendQueue) do
				if activeConfig.receive_function ~= nil then
					activeConfig.receive_function(serdeLayer.WhatIsThis(v.remote, "id"), v.plrs, table.unpack(v.args))
				end

				if not v.invokeReply then
					if v.plrs == "all" then
						local tbl = {}

						table.insert(tbl, v.remote)

						for _, k in ipairs(v.args) do
							table.insert(tbl, k)
						end

						table.insert(toSendAll, tbl)
					elseif typeof(v.plrs) == "table" then
						for _, l in ipairs(v.plrs) do
							if toSendPlayers[l] == nil then
								toSendPlayers[l] = {}
							end

							local tbl = {}

							table.insert(tbl, v.remote)

							for _, m in ipairs(v.args) do
								table.insert(tbl, m)
							end

							table.insert(toSendPlayers[l], tbl)
						end
					else
						if toSendPlayers[v.plrs] == nil then
							toSendPlayers[v.plrs] = {}
						end

						local tbl = {}

						table.insert(tbl, v.remote)

						for _, n in ipairs(v.args) do
							table.insert(tbl, n)
						end

						table.insert(toSendPlayers[v.plrs], tbl)
					end
				elseif v.invokeReply then
					if toSendPlayers[v.plrs] == nil then
						toSendPlayers[v.plrs] = {}
					end

					local tbl = {}

					table.insert(tbl, v.remote)
					table.insert(tbl, InvokeReply)
					table.insert(tbl, v.uuid)

					for _, k in ipairs(v.args) do
						table.insert(tbl, k)
					end

					table.insert(toSendAll, tbl)
				end
			end

			if #toSendAll ~= 0 then
				RemoteEvent:FireAllClients(toSendAll)
			end
			for l, k in pairs(toSendPlayers) do
				RemoteEvent:FireClient(l, k)
			end
			table.clear(SendQueue)
		end

		if (time() - lastReceive) >= receiveRate then
			lastReceive = time()

			for _, v in ipairs(ReceiveQueue) do
				local obj = BridgeObjects[serdeLayer.WhatIsThis(v.remote, "id")]
				if obj == nil then
					--Don't warn here because that's a vulnerability. We don't want exploiters
					--lagging out the server over time with a pcall that warns every frame.
					continue
				end
				if v.args[1] == Invoke then
					if obj._onInvoke ~= nil then
						task.spawn(function()
							local args = v.args
							local uuid = args[2]

							table.remove(args, 1)
							table.remove(args, 1) -- Arg 2 becomes arg1 after arg1 is removed.
							table.insert(SendQueue, {
								plrs = v.plr,
								remote = obj._id,
								uuid = uuid,
								invokeReply = true,
								args = { obj._onInvoke(v.plr, unpack(v.args)) },
							})
						end)
					else
						-- onInvoke is not set send an error to the client
						local args = v.args
						local uuid = args[2]

						table.remove(args, 1)
						table.remove(args, 1) -- Arg 2 becomes arg1 after arg1 is removed.
						table.insert(SendQueue, {
							plrs = v.plr,
							remote = obj._id,
							uuid = uuid,
							invokeReply = true,
							args = { "err", "onInvoke has not yet been registered on the server for " .. obj._name },
						})
					end
				else
					if activeConfig.receive_logging ~= nil then
						activeConfig.receive_logging(v.plr, table.unpack(v.args))
					end

					for callback, timesConnected in pairs(obj._connections) do
						-- Spawn a thread to be yield-safe. Potentially implement thread reusability for optimization later?
						-- also for error protection
						for _ = 1, timesConnected do
							task.spawn(callback, v.plr, unpack(v.args))
						end
					end
				end
			end
			table.clear(ReceiveQueue)
		end

		debug.profileend()
	end)

	RemoteEvent.OnServerEvent:Connect(function(plr, tbl)
		for _, v in ipairs(tbl) do
			local args = v
			local remote = args[1]
			table.remove(args, 1)
			local toInsert = {
				remote = remote,
				plr = plr,
				args = args,
			}
			table.insert(ReceiveQueue, toInsert)
		end
	end)

	return nil
end

function ServerBridge.new(remoteName: string)
	assert(type(remoteName) == "string", "[BridgeNet] Remote name must be a string")

	local found = ServerBridge.from(remoteName)
	if found ~= nil then
		return found
	end

	local self = setmetatable({}, ServerBridge)

	self._name = remoteName

	self._onInvoke = nil
	self._connections = {}
	self._rateInThisMinute = {
		num = 0,
		min = 0,
	}
	self._rateLimit = nil
	self._rateHandler = nil

	self._id = serdeLayer.CreateIdentifier(remoteName)

	self._middleware = function(connectCallback, playerCalling, ...)
		connectCallback(playerCalling, ...)
	end

	BridgeObjects[self._name] = self
	return self
end

function ServerBridge.from(remoteName: string)
	return BridgeObjects[remoteName]
end

function ServerBridge.waitForBridge(remoteName: string)
	while true do
		local bridge = BridgeObjects[remoteName]
		if bridge then
			return bridge
		end
		task.wait()
	end
end

--[=[
	Sends data to a specific player.
	
	```lua
	local Bridge = BridgeNet.CreateBridge("Remote")
	Bridge:FireTo(Players.Someone, "Hello", "World!")
	```
	
	@param plr Player
	@param ... ...any
	@return nil
]=]
function ServerBridge:FireTo(plr: Player, ...: any)
	local args: { any } = { ... }
	local toSend: queueSendPacket = {
		plrs = plr,
		remote = self._id,
		args = args,
	}
	table.insert(SendQueue, toSend)
end

--[=[
	Set the handler for when the server is invoked. By default, this is nil. The client will hang forever as of writing this right now.
	
	```lua
	local Bridge = BridgeNet.CreateBridge("Remote")
	
	local data = Bridge:OnInvoke(function(data)
		if data == "whats 2+2?" then
			return "4"
		end
	end)
	```
	
	@param callback (...any) -> nil
	@return Promise
]=]
function ServerBridge:OnInvoke(callback: (...any) -> nil)
	local function wrappedCallback(...)
		local success, args = pcall(function(...)
			return table.pack(callback(...))
		end, ...)

		if success == true then
			return table.unpack(args)
		else
			return "err", args
		end
	end

	self._onInvoke = wrappedCallback --wrappedCallback
end

--[=[
	Sends data to every player except for one.
	
	```lua
	local Bridge = BridgeNet.CreateBridge("Remote")
	Bridge:FireToAllExcept(Players.Someone, "Hello", "World!")
	Bridge:FireToAllExcept({Players.A, Players.B}, "Not to A or B, but to C.")
	```
	
	@param blacklistedPlrs Player | {Player}
	@param ... ...any
	@return nil
]=]
function ServerBridge:FireToAllExcept(blacklistedPlrs: Player | { Player }, ...: any): { Player }
	local toSend = {}
	for _, v: Player in ipairs(Players:GetPlayers()) do
		if typeof(blacklistedPlrs) == "table" then
			if table.find(blacklistedPlrs, v) then
				continue
			end
		else
			if blacklistedPlrs == v then
				continue
			end
		end
		table.insert(toSend, v)
	end

	local toSendPacket: queueSendPacket = {
		plrs = toSend,
		remote = self._id,
		args = { ... },
	}
	table.insert(SendQueue, toSendPacket)

	return toSend
end

--[=[
	Sends data to every single player within the range except certain blacklisted players. Returns the players affected, for usage later.
	
	```lua
	local Bridge = BridgeNet.CreateBridge("Remote")
	local PlayersSent = Bridge:FireToAllInRangeExcept(
		Players.Someone,
		Vector3.new(50, 50, 50),
		10,
		"Hello",
		"World!"
	)
	
	task.wait(5)
	
	Bridge:FireToMultiple(PlayersSent, "Time for an update!")
	```
	
	@param blacklistedPlrs Player | {Player}
	@param point Vector3
	@param range number
	@param ... ...any
	@return {Player}
]=]
function ServerBridge:FireAllInRangeExcept(
	blacklistedPlrs: Player | { Player },
	point: Vector3,
	range: number,
	...: any
)
	local toSend = {}
	for _, v: Player in ipairs(Players:GetPlayers()) do
		if v:DistanceFromCharacter(point) <= range then
			if typeof(blacklistedPlrs) == "table" then
				if table.find(blacklistedPlrs, v) then
					continue
				end
			else
				if blacklistedPlrs == v then
					continue
				end
			end
			table.insert(toSend, v)
		end
	end

	local toSendPacket: queueSendPacket = {
		plrs = toSend,
		remote = self._id,
		args = { ... },
	}
	table.insert(SendQueue, toSendPacket)

	return toSend
end

--[=[
	Sends data to every single player within the range. Returns the players affected, for usage later.
	
	```lua
	local Bridge = BridgeNet.CreateBridge("Remote")
	local PlayersSent = Bridge:FireAllInRange(
		Vector3.new(50, 50, 50),
		10,
		"Hello",
		"World!"
	)
	
	task.wait(5)
	
	Bridge:FireToMultiple(PlayersSent, "Time for an update!")
	```
	
	@param point Vector3
	@param range number
	@param ... ...any
	@return {Player}
]=]
function ServerBridge:FireAllInRange(point: Vector3, range: number, ...: any): { Player }
	local toSend = {}
	for _, v: Player in ipairs(Players:GetPlayers()) do
		if v:DistanceFromCharacter(point) <= range then
			table.insert(toSend, v)
		end
	end

	local toSendPacket: queueSendPacket = {
		plrs = toSend,
		remote = self._id,
		args = { ... },
	}
	table.insert(SendQueue, toSendPacket)

	return toSend
end

--[=[
	Sends data to every single player, with no exceptions.
	
	```lua
	local Bridge = BridgeNet.CreateBridge("Remote")
	Bridge:FireAll("Hello, world!")
	```
	
	@param ... ...any
	@return nil
]=]
function ServerBridge:FireAll(...: any): nil
	local args: { any } = { ... }
	local toSend: queueSendPacket = {
		plrs = "all",
		remote = self._id,
		args = args,
	}
	table.insert(SendQueue, toSend)
	return nil
end

--[=[
	Sends data to multiple players.
	
	```lua
	local Bridge = BridgeNet.CreateBridge("Remote")
	Bridge:FireToMultiple({Players.A, Players.B}, "Hi!", "Hello.")
	```
	
	@param plrs {Player}
	@param ... ...any
	@return nil
]=]
function ServerBridge:FireToMultiple(plrs: { Player }, ...: any): nil
	local args: { any } = { ... }
	local toSend: queueSendPacket = {
		plrs = plrs,
		remote = self._id,
		args = args,
	}
	table.insert(SendQueue, toSend)
	return nil
end

--[[
	Sets the rate limit, and allows handling when the limit is hit.
	It's possible to override the rate limit with the rate limit handler.
	
	```lua
	local Bridge = BridgeNet.CreateBridge("Remote")
	Bridge:Ratelimit(20, function(sender, number)
		if sender:GetRankInGroup(1234567) >= 60 then
			return true -- Let them through, they're an admin.
		else
			return false
		end
	end)
	```
	
	@param requestsPerMinute number
	@param rateLimitHandler (sender: Player, requests: number) -> boolean?
	@return nil
]]
--[[function ServerBridge:Ratelimit(
	requestsPerMinute: number,
	rateLimitHandler: (sender: Player, requests: number) -> boolean?
)
	self._rateLimit = requestsPerMinute
	self._rateHandler = rateLimitHandler
		or function(sender, requests)
			warn(
				("Player %s is sending too many requests! Sent %c this minute, when the limit is %d per minute."):format(
					sender.Name,
					requests,
					self._rateLimit
				)
			)
		end
end]]

--[[
	Sets the middleware function to be used. You must call the connection callback or it won't run.
	Keep in mind, even if the middleware says not to run the connections, it will still affect rate limits.
	
	```lua
	local Bridge = BridgeNet.CreateBridge("Remote")
	Bridge:SetMiddleware(function(connectionCallback, playerCalling, ...)
		if playerCalling:GetRankInGroup(1234567) >= 60 then
			connectionCallback(...)
		else
			return
		end
	end)
	```
	
	@param func (connectCallback: () -> nil, playerCalling: Player, ...) -> nil
	@return nil
]]
--[[function ServerBridge:SetMiddleware(func: (connectCallback: () -> nil, playerCalling: Player) -> nil) -- for some reason varargs don't play nicely with types
	self._middleware = func
end]]

--[=[
	Creates a connection.
	
	```lua
	local Bridge = BridgeNet.CreateBridge("Remote")
	Bridge:Connect(function(plr, data)
		print(plr .. " has sent " .. data)
	end)
	```
	
	@param func (plr: Player, ...any) -> nil
	@return Connection
]=]
function ServerBridge:Connect(func: (...any) -> nil)
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
	Gets the ServerBridge's name.
	
	```lua
	local Bridge = ServerBridge.new("Remote")
	
	print(Bridge:GetName()) -- Prints "Remote"
	```
	
	@return string
]]
function ServerBridge:GetName()
	return self._name
end

--[=[
	Destroys the identifier, and deletes the object reference.
	
	```lua
	local Bridge = BridgeNet.CreateBridge("Remote")
	Bridge:Destroy()
	
	Bridge:FireTo(Players.A) -- Errors, the object is deleted.
	```
	
	@return nil
]=]
function ServerBridge:Destroy()
	BridgeObjects[self._name] = nil
	serdeLayer.DestroyIdentifier(self.Name)
	for k, v in ipairs(self) do
		if v.Destroy ~= nil then
			v:Destroy()
		else
			self[k] = nil
		end
	end
	setmetatable(self, nil)
end

return ServerBridge
