local RunService = game:GetService("RunService")
local ServerBridge = require(script.Parent.ServerBridge)
local ClientBridge = require(script.Parent.ClientBridge)

local function search(name, v)
	local ReturnValue
	local bridge = if RunService:IsServer() then ServerBridge.new(name) else ClientBridge.new(name)

	-- Server-only
	if RunService:IsServer() then
		if v["middleware"] then
			bridge:SetMiddleware(v.middleware)
		end
	end

	if v["replicationrate"] then
		bridge:SetReplicationRate(v.replicationrate)
	end

	ReturnValue = bridge

	return ReturnValue
end

local function recursiveSearch(passedTable)
	local ReturnValue = {}
	for k, v in passedTable do
		assert(
			type(v) == "table",
			"Everything in BridgeNet.CreateBridgeTree must be a dictionary or BridgeNet.Bridge()"
		)

		if v._isBridge == true then
			ReturnValue[k] = search(k, v)
		else
			ReturnValue[k] = recursiveSearch(v)
			continue
		end
	end
	return ReturnValue
end

return recursiveSearch
