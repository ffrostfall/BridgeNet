local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local serdeLayer = require(script.Parent.serdeLayer)
local rateManager = require(script.Parent.rateManager)

type queueSendPacket = { plrs: string | Player | { Player }, remote: string, args: { any } }

type queueReceivePacket = { plr: Player, remote: string, args: { any } }

type config = {
	send_default_rate: number,
	receive_default_rate: number,
	--one_remote_event: boolean,
}

local SendQueue: { queueSendPacket } = {}
local ReceiveQueue: { queueReceivePacket } = {}

local BridgeObjects = {}

local lastClear: number = 0

local lastSend: number = 0
local lastReceive: number = 0

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

	rateManager.SetSendRate(activeConfig.send_default_rate)
	rateManager.SetReceiveRate(activeConfig.receive_default_rate)

	RunService.Heartbeat:Connect(function()
		debug.profilebegin("ServerBridge")
		local sendRate = rateManager.GetSendRate()
		local receiveRate = rateManager.GetReceiveRate()

		if (os.clock() - lastClear) > 60 then
			lastClear = os.clock()

			for _, v in pairs(BridgeObjects) do
				v._rateInThisMinute = 0
			end
		end

		if (os.clock() - lastSend) >= sendRate then
			lastSend = os.clock()

			local toSendAll = {}
			local toSendPlayers = {}
			for _, v in pairs(SendQueue) do
				if v.plrs == "all" then
					table.insert(toSendAll, {
						v.remote,
						v.args,
					})
				elseif typeof(v.plrs) == "table" then
					for _, k in pairs(v.plrs) do
						if toSendPlayers[k] == nil then
							toSendPlayers[k] = {}
						end
						table.insert(toSendPlayers[k], {
							v.remote,
							v.args,
						})
					end
				else
					if toSendPlayers[v.plrs] == nil then
						toSendPlayers[v.plrs] = {}
					end
					table.insert(toSendPlayers[v.plrs], {
						v.remote,
						v.args,
					})
				end
			end

			RemoteEvent:FireAllClients(toSendAll)
			for l, k in pairs(toSendPlayers) do
				RemoteEvent:FireClient(l, k)
			end
			SendQueue = {}
		end

		if (os.clock() - lastReceive) >= receiveRate then
			lastReceive = os.clock()

			for _, v in pairs(ReceiveQueue) do
				local obj = BridgeObjects[serdeLayer.WhatIsThis(v.remote, "id")]

				for _, k in pairs(obj._connections) do
					k(v.plr, table.unpack(v.args))
				end
			end
			ReceiveQueue = {}
		end

		debug.profileend()
	end)

	RemoteEvent.OnServerEvent:Connect(function(plr, tbl)
		for _, v in pairs(tbl) do
			table.insert(ReceiveQueue, {
				remote = v[1],
				plr = plr,
				args = v[2],
			})
		end
	end)

	return nil
end

function ServerBridge.new(remoteName: string)
	local self = setmetatable({}, ServerBridge)

	self._name = remoteName

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

--[=[
	Sends data to a specific player.
	
	```lua
	local Bridge = Network.CreateBridge("Remote")
	Bridge:FireTo(game.Players.Someone, "Hello", "World!")
	```
	
	@param plr Player
	@param ... ...any
	@return nil
]=]
function ServerBridge:FireTo(plr: Player, ...: any)
	local args: { any } = table.pack(...)
	local toSend: queueSendPacket = {
		plrs = plr,
		remote = self._id,
		args = table.pack(...),
	}
	table.insert(SendQueue, toSend)
end

--[=[
	Sends data to every player except for one.
	
	```lua
	local Bridge = Network.CreateBridge("Remote")
	Bridge:FireToAllExcept(game.Players.Someone, "Hello", "World!")
	Bridge:FireToAllExcept({game.Players.A, game.Players.B}, "Not to A or B, but to C.")
	```
	
	@param blacklistedPlrs Player | {Player}
	@param ... ...any
	@return nil
]=]
function ServerBridge:FireToAllExcept(blacklistedPlrs: Player | { Player }, ...: any): { Player }
	local toSend = {}
	for _, v: Player in pairs(game:GetService("Players"):GetPlayers()) do
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
		args = table.pack(...),
	}
	table.insert(SendQueue, toSendPacket)

	return toSend
end

--[=[
	Sends data to every single player within the range except certain blacklisted players. Returns the players affected, for usage later.
	
	```lua
	local Bridge = Network.CreateBridge("Remote")
	local PlayersSent = Bridge:FireToAllInRangeExcept(
		game.Players.Someone,
		Vector3.new(50,50,50),
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
	for _, v: Player in pairs(game:GetService("Players"):GetPlayers()) do
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
		args = table.pack(...),
	}
	table.insert(SendQueue, toSendPacket)

	return toSend
end

--[=[
	Sends data to every single player within the range. Returns the players affected, for usage later.
	
	```lua
	local Bridge = Network.CreateBridge("Remote")
	local PlayersSent = Bridge:FireAllInRange(
		Vector3.new(50,50,50),
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
	for _, v: Player in pairs(game:GetService("Players"):GetPlayers()) do
		if v:DistanceFromCharacter(point) <= range then
			table.insert(toSend, v)
		end
	end

	local toSendPacket: queueSendPacket = {
		plrs = toSend,
		remote = self._id,
		args = table.pack(...),
	}
	table.insert(SendQueue, toSendPacket)

	return toSend
end

--[=[
	Sends data to every single player, with no exceptions.
	
	```lua
	local Bridge = Network.CreateBridge("Remote")
	Bridge:FireAll("Hello, world!")
	```
	
	@param ... ...any
	@return nil
]=]
function ServerBridge:FireAll(...: any): nil
	local args: { any } = table.pack(...)
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
	local Bridge = Network.CreateBridge("Remote")
	Bridge:FireToMultiple({game.Players.A, game.Players.B}, "Hi!", "Hello.")
	```
	
	@param plrs {Player}
	@param ... ...any
	@return nil
]=]
function ServerBridge:FireToMultiple(plrs: { Player }, ...: any): nil
	local args: { any } = table.pack(...)
	local toSend: queueSendPacket = {
		plrs = plrs,
		remote = self._id,
		args = args,
	}
	table.insert(SendQueue, toSend)
	return nil
end

--[=[
	Sets the rate limit, and allows handling when the limit is hit.
	It's possible to override the rate limit with the rate limit handler.
	
	```lua
	local Bridge = Network.CreateBridge("Remote")
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
]=]
function ServerBridge:Ratelimit(
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
end

--[=[
	Sets the middleware function to be used. You must call the connection callback or it won't run.
	Keep in mind, even if the middleware says not to run the connections, it will still affect rate limits.
	
	```lua
	local Bridge = Network.CreateBridge("Remote")
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
]=]
function ServerBridge:SetMiddleware(func: (connectCallback: () -> nil, playerCalling: Player) -> nil) -- for some reason varargs don't play nicely with types
	self._middleware = func
end

--[=[
	Creates a connection.
	
	```lua
	local Bridge = Network.CreateBridge("Remote")
	Bridge:Connect(function(plr, data)
		print(plr .. " has sent " .. data)
	end)
	```
	
	@param func (plr: Player, ...any) -> nil
	@return Connection
]=]
function ServerBridge:Connect(func: (plr: Player, ...any) -> nil)
	local index = table.insert(self._connections, func)
	return {
		Disconnect = function()
			table.remove(self._connections, index)
		end,
	}
end

--[=[
	Destroys the identifier, and deletes the object reference.
	
	```lua
	local Bridge = Network.CreateBridge("Remote")
	Bridge:Destroy()
	
	Bridge:FireTo(game.Players.A) -- Errors, the object is deleted.
	```
	
	@return nil
]=]
function ServerBridge:Destroy()
	serdeLayer.DestroyIdentifier(self.Name)
	for k, v in pairs(self) do
		if v.Destroy ~= nil then
			v:Destroy()
		else
			self[k] = nil
		end
	end
	setmetatable(self, nil)
end

return ServerBridge
