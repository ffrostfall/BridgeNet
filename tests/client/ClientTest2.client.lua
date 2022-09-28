local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage.Packages.BridgeNet)

local STRESS_TEST = true
local BRIDGENET_OR_ROBLOX = "roblox"

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
			RemoteB = BridgeNet.Bridge({
				ReplicationRate = 45,
				Server = {
					OutboundMiddleware = {
						function(...)
							print("CreateBridgeTree server middleware outgoing")
							return ...
						end,
					},
					InboundMiddleware = {
						function(plr, ...)
							print("CreateBridgeTree server middleware inbound: " .. plr.Name)
							return ...
						end,
					},
				},
				Client = {
					OutboundMiddleware = {
						function(...)
							print("CreateBridgeTree client middleware outgoing")
							return ...
						end,
					},
					InboundMiddleware = {
						function(...)
							print("CreateBridgeTree client middleware inbound")
							return ...
						end,
					},
				},
			}),
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

	local connection = Bridges.RemoteA:Connect(function(arg1)
		print(arg1)
	end)

	Bridges.RemoteCategory.RemoteB:Connect(function() end)

	local lastTwentyHz = 0
	BridgeNet.ReplicationStep(20, function()
		print(os.clock() - lastTwentyHz)
		lastTwentyHz = os.clock()
	end)

	task.delay(5, function()
		connection:Disconnect()
	end)

	while true do
		Bridges.RemoteCategory.RemoteB:Fire("client to server check")
		Bridges.RemoteCategory.RemoteB:InvokeServerAsync("Args working")
		task.wait(2)
	end
elseif STRESS_TEST then
	if BRIDGENET_OR_ROBLOX == "bridgenet" then
		local stresser = BridgeNet.CreateBridge("stresser")

		stresser:Connect(function() end)
	elseif BRIDGENET_OR_ROBLOX == "roblox" then
		local stresser = ReplicatedStorage:WaitForChild("TestEvent")

		stresser.OnClientEvent:Connect(function() end)
	end
end
