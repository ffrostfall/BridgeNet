local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage.Packages.BridgeNet)

BridgeNet.Start({})

local Bridges = BridgeNet.CreateBridgeTree({
	RemoteA = BridgeNet.Bridge({}),
	RemoteCategory = {
		RemoteB = BridgeNet.Bridge({}),
		RemoteC = BridgeNet.Bridge({}),
	},
})

if Bridges["RemoteA"] == nil then
	error(".Declare error, RemoteA is nil")
end

if Bridges["RemoteCategory"] == nil then
	error("RemoteCategory is nil")
end

if Bridges.RemoteCategory["RemoteB"] == nil then
	error(".Declare error, RemoteB is nil")
end

if Bridges.RemoteA["_id"] == nil and Bridges.RemoteA["_name"] == nil then
	error(".Declare does not return a bridge")
end

while task.wait(2) do
	Bridges.RemoteA:FireAll("FireAll check")
	Bridges.RemoteA:FireTo(game.Players:GetPlayers()[1], "FireTo check")
end
