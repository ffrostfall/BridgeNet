local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage.Packages.BridgeNet)

local RunService = game:GetService("RunService")

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
			RemoteAA = BridgeNet.Bridge({
				ReplicationRate = 20,
			}),
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

	Bridges.RemoteCategory.RemoteB:Connect(function(plr, arg1)
		print(plr, arg1)
	end)

	Bridges.RemoteCategory.RemoteB:OnInvoke(function(plr, arg2)
		print("Invoke working")
		print(plr, arg2)
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

	while task.wait(2) do
		Bridges.RemoteA:FireAll("FireAll check")
		Bridges.RemoteA:FireTo(game.Players:GetPlayers()[1], "FireTo check")
		task.defer(function()
			task.wait()
			print(BridgeNet.GetQueue())
		end)
		Bridges.RemoteCategory.RemoteB:FireTo(game.Players:GetPlayers()[1], "Middleware check")

		Bridges.RemoteCategory.RemoteAA:FireAll("Queueing test")

		Bridges.RemoteA:FireAll("Rapid")
		Bridges.RemoteA:FireAll("Succession")
		Bridges.RemoteA:FireAll("Check")
	end
elseif STRESS_TEST then
	local stresser = BridgeNet.CreateBridge("stresser")
	RunService.Heartbeat:Connect(function()
		for _ = 1, 200 do
			stresser:FireAll()
		end
	end)
end
