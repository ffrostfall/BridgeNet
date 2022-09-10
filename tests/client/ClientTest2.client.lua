local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage.Packages.BridgeNet)

BridgeNet.Start({})

local Bridges = BridgeNet.CreateBridgeTree({
	RemoteA = BridgeNet.Bridge({}),
	RemoteCategory = {
		RemoteB = BridgeNet.Bridge({
			Name = "RemoteB",
		}),
		RemoteC = BridgeNet.Bridge({
			Name = "RemoteC",
		}),
	},
})

Bridges.RemoteA:Connect(function(arg1)
	print("received:")
	print(arg1)
	print("--------------")
end)
