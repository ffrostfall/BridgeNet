local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("BridgeNet"))

BridgeNet.Start({
	[BridgeNet.ReceiveLogFunction] = function(remoteName, ...)
		print(...)
	end,
	[BridgeNet.SendLogFunction] = function(remoteName, ...)
		print(...)
	end,
	[BridgeNet.DefaultSend] = 60,
	[BridgeNet.DefaultReceive] = 60,
})

local Object = BridgeNet.CreateBridge("Test")

local TestRemote = Instance.new("RemoteEvent")
TestRemote.Name = "TestRemote"
TestRemote.Parent = ReplicatedStorage

Object:Connect(function(plr, ...)
	print(plr, ...)
end)

Object:OnInvoke(function(plr, arg1, arg2)
	print(plr)
	return "it works!", "yeah."
end)

local test = BridgeNet.CreateBridgesFromDictionary({
	Something = "Key1",
	SomethingB = "Key2",
	IsItDeep = {
		Yes = "No",
		TestA = "TestA",
		Again = {
			TestB = "TestB",
		},
	},
})

Object:SetMiddleware({
	function(...)
		return ...
	end,
	function(...)
		print("1")
		return ...
	end,
	function(...)
		print("2")
		return ...
	end,
})

while task.wait(1) do -- For normal tests, do task.wait
	Object:FireTo(Players:GetPlayers()[1], "Received: Fire", "Test", "Test2")
	print(Object:FireAllInRange(Vector3.new(0, 0, 0), 50, "Received: FireAllInRange", " Client within range! "))
	Object:FireAll("Received: FireAll", "Test", "Test2")

	-- When stress testing, set the task.wait(1) to task.wait().
	--[[for i = 1, 200 do
		Object:FireAll()
	end
	for i = 1, 200 do
		TestRemote:FireAllClients()
	end]]
end
