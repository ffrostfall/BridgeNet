local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage:WaitForChild("BridgeNet"))

BridgeNet.Start({
	send_default_rate = 60,
	receive_default_rate = 60,
})

local Object = BridgeNet.CreateBridge("Test")

local TestRemote = Instance.new("RemoteEvent")
TestRemote.Name = "TestRemote"
TestRemote.Parent = ReplicatedStorage

Object:Connect(function(plr, arg1, arg2)
	print(plr, arg1)
end)

while task.wait(1) do
	Object:FireTo(game.Players:GetPlayers()[1], "Received: Fire")
	print(Object:FireAllInRange(Vector3.new(0, 0, 0), 50, "Received: FireAllInRange"))
	Object:FireAll("Received: FireAll")
	--[[for i = 1, 200 do
		Object:FireAll()
	end
	for i = 1, 200 do
		TestRemote:FireAllClients()
	end]]
end
