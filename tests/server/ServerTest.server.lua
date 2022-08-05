local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage:WaitForChild("BridgeNet"))

BridgeNet.Start({
	send_default_rate = 60,
	receive_default_rate = 60,
})

local Object = BridgeNet.CreateBridge("Test")

Object:Connect(function(plr, arg1, arg2, arg3)
	print("Server received message ok!")
	print(plr, arg1, arg2, arg3)
end)

while task.wait(1) do
	Object:FireAll("Firing all, received ok!")
	Object:FireToMultiple(Players:GetPlayers()[1], "Firing multiple, received ok!")
	print(Object:FireAllInRange(Vector3.new(0, 0, 0), 10, "Firing all in range, received ok!"))
	Object:FireTo(game.Players:GetPlayers()[1], "fired specific player, received ok!")
	print(Object:FireToAllExcept(game.Players:GetPlayers()[1], "fired all except this player, received ok!"))
	print(
		Object:FireAllInRangeExcept(
			game.Players:GetPlayers()[1],
			Vector3.new(0, 0, 0),
			50,
			"fired all in range except player, received ok!"
		)
	)
end
