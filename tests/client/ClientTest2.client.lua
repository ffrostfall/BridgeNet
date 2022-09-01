local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage.Packages.BridgeNet)

local Bridges = BridgeNet.Declare({
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
