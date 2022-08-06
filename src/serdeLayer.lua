--!strict
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService: RunService = game:GetService("RunService")

local receiveDict: { [string]: string } = {}
local sendDict: { [string]: string } = {}
local numOfSerials: number = 0

--[=[
	@class serdeLayer
	
	This module handles serialization and deserialization for you.
]=]
local serdeLayer = {}

local AutoSerde: Folder = nil

type toSend = string

if RunService:IsClient() then
	AutoSerde = ReplicatedStorage:WaitForChild("AutoSerde")
	for _, v in pairs(AutoSerde:GetChildren()) do
		local strValue = v :: StringValue
		sendDict[strValue.Name] = strValue.Value
		receiveDict[strValue.Value] = strValue.Name
	end
	AutoSerde.ChildAdded:Connect(function(child: Instance)
		local strValue = child :: StringValue
		sendDict[strValue.Name] = strValue.Value
		receiveDict[strValue.Value] = strValue.Name
	end)
	AutoSerde.ChildRemoved:Connect(function(child: Instance)
		local strValue = child :: StringValue
		sendDict[strValue.Name] = nil
		receiveDict[strValue.Value] = nil
	end)
else
	AutoSerde = Instance.new("Folder")
	AutoSerde.Name = "AutoSerde"
	AutoSerde.Parent = ReplicatedStorage
end

--[=[
	This takes a compressed value and returns the identification related to it, and does the reverse.	

	```lua
		print(BridgeNet.WhatIsThis("SomeIdentificationStringHere")) -- prints the compressed value
	```
	
	@param str string
	@param toSend "id" | "compressed"
	@return string?
]=]
function serdeLayer.WhatIsThis(str: string, toSend: toSend): string?
	if toSend == "id" then
		return receiveDict[str]
	elseif toSend == "compressed" then
		return sendDict[str]
	end
	return error("toSend is not receive or send.")
end

--[=[
	This creates an identifier and associates it with a compressed value. This is shared between the server and the client.

	```lua
		BridgeNet.CreateIdentifier("Something")
		
		print(BridgeNet.WhatIsThis("Something", "compressed"))
	```
	
	@param id string
	@return nil
]=]
function serdeLayer.CreateIdentifier(id: string): string
	assert(RunService:IsServer(), "You cannot create identifiers on the client.")

	if numOfSerials > 65536 then
		error("Over the identification cap: " .. id)
	end
	numOfSerials += 1

	local StringValue = Instance.new("StringValue")
	StringValue.Name = id
	StringValue.Value = string.pack("H", numOfSerials)
	StringValue.Parent = AutoSerde

	sendDict[id] = StringValue.Value
	receiveDict[StringValue.Value] = id

	return StringValue.Value
end

--[=[
	This creates an identifier and associates it with a compressed value. This is shared between the server and the client.

	```lua
		BridgeNet.DestroyIdentifier("Something")
		
		print(BridgeNet.WhatIsThis("Something", "compressed")) -- Errors
	```
	
	@param id string
	@return nil
]=]
function serdeLayer.DestroyIdentifier(id: string): nil
	assert(RunService:IsServer(), "You cannot destroy identifiers on the client.")

	receiveDict[sendDict[id]] = nil
	sendDict[id] = nil

	numOfSerials -= 1

	AutoSerde:FindFirstChild(id):Destroy()
	return nil
end

return serdeLayer
