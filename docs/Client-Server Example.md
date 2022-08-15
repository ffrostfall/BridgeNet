---
sidebar_position: 5
---

# Client-Server Example

## Server
```lua name="example.server.lua"
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage.Packages.BridgeNet)

BridgeNet.Start({})

local Remote = BridgeNet.CreateBridge("Remote")

Remote:Connect(function(plr, stringA, stringB)
	print(stringA .. stringB) -- Prints "Hello, server!"
end)
```

## Client
```lua name="example.client.lua"
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage.Packages.BridgeNet)

BridgeNet.Start({})

local Remote = BridgeNet.CreateBridge("Remote")

while true do
	Remote:Fire("Hello, ", "server!")
	
	task.wait(1)
end
```