local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage.Packages.BridgeNet)

local STRESS_TEST = false

if not STRESS_TEST then
	local uuid = BridgeNet.CreateUUID()
	print(uuid)
	local packed = BridgeNet.PackUUID(uuid)
	print(packed)
	print(BridgeNet.UnpackUUID(packed))

	local Identifiers = BridgeNet.Identifiers({
		"Test",
		"Funny",
		"Haha",
		"TestB",
		"yes",
	})
	print(Identifiers)

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

	Bridges.RemoteCategory.RemoteB:SetInboundMiddleware({
		function(...)
			return ...
		end,
		function(...)
			print("Inbound Middleware working")
			return ...
		end,
	})

	Bridges.RemoteCategory.RemoteB:SetOutboundMiddleware({
		function(...)
			return ...
		end,
		function(...)
			print("Outbound Middleware working")
			return ...
		end,
	})

	Bridges.RemoteCategory.RemoteB:Connect(function() end)

	local lastTwentyHz = 0
	BridgeNet.ReplicationStep(20, function()
		print(os.clock() - lastTwentyHz)
		lastTwentyHz = os.clock()
	end)

	while true do
		Bridges.RemoteCategory.RemoteB:Fire("client to server check")
		Bridges.RemoteCategory.RemoteB:InvokeServerAsync("Args working")
		task.wait(2)
	end
elseif STRESS_TEST then
	local stresser = BridgeNet.CreateBridge("stresser")

	stresser:Connect(function() end)
end
