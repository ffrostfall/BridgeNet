# 1.9.9-beta
- Functions that rely on .Start will yield until started

# 1.9.8-beta
- Switched for loops to be generics for consistency. This should help performance.
- Switched time limit to be .5 milliseconds
- Fixed Bridge:Destroy()?
- Type improvements

# 1.9.7-beta
- BridgeNet.Started has been added
- Middleware fixes. Should be stable now

# 1.8.7-beta
- Hotfix for ClientObject:Fire()

# 1.8.6-beta
- You can now pass nil as parameters

# 1.8.5-beta
- Added better performance profiling
- Added ExceededTimeLimit signal
- Added InternalError signal (Unused for now)
- Added server-sided middleware (no typescript support yet, sorry ): [UNSTABLE]
	- Added :SetMiddleware()
	- Added :AddMiddleware()
	- Middleware will be added to the client soon enough
- Added .CreateIdentifiersFromDictionary
- Added .WaitForIdentifier, client-sided only.
- ReceiveLogFunction and SendLogFunction are now stable and ready to be used
- Fixed symbols for roblox-ts(?)
- Improved typings for Luau
- Better error handling

# 1.7.5-beta
- Improved typings for both ts and luau
- Re-added :Once()
- Updated dependency versions

# 1.6.5-beta
- Fixed invokes
- Added documentation for invokes
- Added .CreateBridgesFromDictionary()
- Significantly improved / fixed roblox-ts typings

# 1.5.5-beta
- Added "RemoteFunction"-type API
	- Added ServerBridge:OnInvoke(function() end)
	- Added ClientBridge:InvokeServerAsync(), yields.
	- Added ClientBridge:InvokeServer(), returns a promise instead of yielding.
- Refactored some code to be better-organized.
- Refactored project structure / testing code to allow for dependencies
- Added Promise as a dependency
- Added GoodSignal as a dependency

# 1.4.5-beta
- Ported to typescript!

# 1.4.4-beta
- You no longer need to declare DefaultReceive and DefaultSend- they default to 60.
- Fixed ServerBridge:Destroy()
- Added print message while waiting for the ClientBridge to be replicated
- Removed the print statement in OnClientEvent. oops!

# 1.4.3-beta
- Removed .FromBridge, use .WaitForBridge or .CreateBridge (createbridge returns the existing bridge object if it exists)
- Configuration object now uses symbols instead of regular strings
- Added global custom logging support. UNSTABLE, DONT USE IN PRODUCTION
- Changed some loops to use ipairs instead of pairs
- Used table.clear instead of tbl = {} for better efficiency
- Fixed Disconnect
- Optimizations (thank you @Baileyeatspizza)
- Fixed ClientBridge breaking if the client's bridge was created before the server created the bridge (thank you evanchan0819)
- Fixed client-to-server communication only sending the first argument

# 0.4.3-alpha
- Connections now spawn a thread, making them yield-safe and error-proof.
- Added .WaitForBridge()
- Added Roact's Symbol class- not used for now, will be used for .Start configuration in the future.
- .CreateBridge() now has the same functionality of .FromBridge()
- Server now checks for the BridgeObject to exist before trying to run connections. If it doesn't exist, nothing happens.

# 0.3.3-alpha
- Hotfix for .CreateIdentifier()

# 0.3.2-alpha
- Connections now use pairs instead of ipairs

# 0.3.1-alpha
- Better error handling / messages
- Removed unused function in ServerBridge/ClientBridge.
- Added .CreateUUID(), .PackUUID(), .UnpackUUID(). (ty Pyseph!)
- Added .DictionaryToTable(), which converts a dictionary into an alphabetically-ordered table.
- Switched .ChildAdded for the client's serdeLayer to be in serdeLayer._start()
- Switched "Network" documentation to be "BridgeNet"- Network was a working title.
- Removed one_remote_event from config.

# 0.2.1-alpha
- Better error handling and messages
- Errors during send/receive will not repeat due to failure to clear queue
- If the queue is blank, it will not send. 

## 0.2.0-alpha
- Some optimizations and polishing
- Added .FromBridge(), which lets you get a Bridge object from wherever.
- Fixed an issue where an unused artifact was being sent, increasing size drastically
- Fixed multiple documentation mistakes

## 0.1.0-alpha
- Initial release