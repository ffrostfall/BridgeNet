local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage.Packages.BridgeNet)

BridgeNet.Start({})

local STRESS_TEST = false

if not STRESS_TEST then
	local Bridges = BridgeNet.CreateBridgeTree({
		RemoteA = BridgeNet.Bridge({
			ReplicationRate = 20,
		}),
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

	Bridges.RemoteA:Connect(function(arg1)
		print(arg1)
	end)

	while true do
		Bridges.RemoteCategory.RemoteB:Fire("client to server check")
		Bridges.RemoteCategory.RemoteB:InvokeServer("Args working")
		task.wait(2)
	end
else
	local StressTest = BridgeNet.CreateBridge("StressTest")
end
