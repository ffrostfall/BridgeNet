---
sidebar_position: 3
---

# Getting Started
BridgeNet uses objects known as "bridges". These objects are the equivalent of RemoteEvents in normal Roblox. They are created as such:
```lua title="init.lua"
local Bridge = BridgeNet.CreateBridge("RemoteNameHere")
Bridge:FireAll("Firing all players")
```
All the optimizations are handled for you! These are packaged, sent out with a compressed string ID, and received on the client.

## Using the identifier system
A common pattern in Roblox are string constants that are sent over the wire as their full identity, which wastes data- they never change. 
Identifier strings are 1-2 character strings that represent constant strings which you define. This saves on bandwith because sending shorter strings
instead of longer strings saves on data. These are typically static, and can depict things like action requests, item names, all of that. 
This library provides an easy system to optimize these: the 2 functions ``CreateIdentifier`` and ``DestroyIdentifier``. They are used as such:
```lua title="spellHandler.client.lua"
local SpellCaster = BridgeNet.CreateBridge("SpellCaster")

local Fireball = BridgeNet.CreateIdentifier("Fireball")

SomeUserInputSignalHere:Connect(function()
	SpellCaster:Fire(Fireball) -- Fires a 1 or 2 character string, much smaller than an 8-character string.
end)
```