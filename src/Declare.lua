local RunService = game:GetService("RunService")
local ServerBridge = require(script.Parent.ServerBridge)
local ClientBridge = require(script.Parent.ClientBridge)

return function(tbl)
	local ReturnValue = {}
	for k, v in tbl do
		if v._isBridge == true then
			if RunService:IsServer() then
				ReturnValue[k] = ServerBridge.new(v.name)
				if v.middleware then
					ServerBridge:SetMiddleware(v.middleware)
				end
				if v.rate then
					ServerBridge:SetRate(v.rate)
				end
				if v.maxRate then
					ServerBridge:SetMaxPerMin(v.maxRate)
				end
			else
				
			end
		else
			continue
		end
	end
	return ReturnValue
end
