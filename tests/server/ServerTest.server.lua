local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("BridgeNet"))

BridgeNet.Start({
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

while task.wait(1) do -- For normal tests, do task.wait
	Object:FireTo(game.Players:GetPlayers()[1], "Received: Fire", "Test")
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
