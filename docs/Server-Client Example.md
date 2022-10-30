---
sidebar_position: 4
---

# Server-Client Example

## Server
```lua name="example.server.lua"
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage.Packages.BridgeNet)

local Remote = BridgeNet.CreateBridge("Remote")

while true do
	Remote:FireAll("Hello, ", "world!") -- Fires to everyone
	Remote:FireTo(game.Players.Someone, "Hello, ", "someone!") -- Fires to a specific player
	task.wait(1)
end
```

## Client
```lua name="example.client.lua"
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage.Packages.BridgeNet)

local Remote = BridgeNet.CreateBridge("Remote")

Remote:Connect(function(stringA, stringB)
	print(stringA .. stringB) -- Prints "Hello, someone!"
end)
```