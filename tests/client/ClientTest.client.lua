local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage:WaitForChild("BridgeNet"))

BridgeNet.Start({
	send_default_rate = 60,
	receive_default_rate = 60,
})

local Object = BridgeNet.CreateBridge("Test")

local TestRemote = ReplicatedStorage:WaitForChild("TestRemote")

TestRemote.OnClientEvent:Connect(function() end)

Object:Connect(function(arg1, arg2, arg3)
	print(arg1) -- Comment this out when stress testing. It'll lag heavily and produce incorrect results
end)

while task.wait(1) do
	Object:Fire("Hello", "world")
end
