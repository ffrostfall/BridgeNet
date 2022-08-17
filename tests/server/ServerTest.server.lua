local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("BridgeNet"))

BridgeNet.Start({
	[BridgeNet.ReceiveLogFunction] = function(remoteName, ...)
		print(table.pack(...))
	end,
	[BridgeNet.SendLogFunction] = function(remoteName, ...)
		print(table.pack(...))
	end,
	[BridgeNet.DefaultSend] = 60,
	[BridgeNet.DefaultReceive] = 60,
})

local Object = BridgeNet.CreateBridge("Test")

local TestRemote = Instance.new("RemoteEvent")
TestRemote.Name = "TestRemote"
TestRemote.Parent = ReplicatedStorage

Object:Connect(function(plr, arg1, arg2, arg3)
	print(plr, arg1, arg2, arg3)
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
	function(plr, arg1, arg2, arg3)
		print(plr)
		return arg1, arg2, arg3
	end,
	function(arg1, arg2, arg3)
		print("1")
		return arg1, arg2, arg3
	end,
	function(arg1, arg2, arg3)
		print("2")
		return arg1, arg2, arg3
	end,
})

while task.wait(1) do -- For normal tests, do task.wait
	Object:FireTo(Players:GetPlayers()[1], "Received: Fire", "Test")
	print(Object:FireAllInRange(Vector3.new(0, 0, 0), 50, "Received: FireAllInRange"))
	Object:FireAll("Received: FireAll", "Test")

	-- When stress testing, set the task.wait(1) to task.wait().
	--[[for i = 1, 200 do
		Object:FireAll()
	end
	for i = 1, 200 do
		TestRemote:FireAllClients()
	end]]
end
