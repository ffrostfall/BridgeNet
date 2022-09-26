# Changelog
As of v2.0.0, this project now adheres to semver.

## Unreleased
- Added .ReplicationStep(rate) signal- you can now listen for when a certain replication tick occurs.

## 2.0.0-rc4
- Unpacked arguments on server receive (Thank you @MELON-Om4r)
- Fixed numerous queue-related bugs
- Invoke UUIDs are now packed for less network usage (34 bytes -> 18 bytes)
- The Identifiers function is a closure again
- Added outbound middleware
- Added middleware to the client
- Middleware now passes in the ``plr`` argument on the server
- Overall middleware improvements
- Client-sided improvements w/ connections
- Added .GetQueue() for debugging purposes
- General improvements to client receive
- Temporarily removed warning signals until I can figure out a better way to add them, they're kind of a mess right now.
- Removed config symbols
- Removed logging features- it turns out I forgot to fully implement them, plus nobody used them.
- **Removed BridgeNet.Start(), the module now runs when you require it for the first time.**
- Removed :InvokeServer()
- Removed both dependencies
- Updated typescript port
- Fixed Docusaurus dependency- oops.

## 2.0.0-rc3
- Multiple :Fire()s can be sent in the same frame
- Performance improvements
- Bugfixes w/ SerdesLayer & replication
- Added more test cases- 2.0.0 should be usable and more stable.
- Fixed invokes

## 2.0.0-rc2
- Middleware now is defaulted off if there's nothing in the table
- Some small improvements
- Renamed ``Declare`` to ``CreateBridgeTree``
- Exposed the typings ``Bridge``, ``ClientBridge`` and ``ServerBridge`` to the user.
- Added ``Bridge:SetReplicationRate()``
- Started on a better way of doing releases for wally and non-wally. Kinda experimenting right now!

## 2.0.0-rc1
- Removed rateManager entirely
- Removed .CreateIdentifiersFromDictionary()
- Removed .CreateBridgesFromDictionary()
- Removed .WhatIsThis()
- Removed .WaitForBridge()
- Removed PrintRemotes symbol- it was useless.
- Added GetCompressedIdentifier
- Added .Declare()
- Added .Identifiers()
- Added .GetFromCompressed()
- Added .GetFromIdentifier()
- Each BridgeObject now has a variable rate it sends information at. This is by default 60.
- A lot of functions are now modules that return a function
- Repeat loops are now while loops
- Renamed serdeLayer to SerdesLayer
- Optimizations
- Symbols are now loaded in via a module
- Added hot reloading support(?)
- Rewrote test code

### Changes to be done
- Remove receive queueing
- Typings should use ``never`` and ``unknown`` types
- Add :SetReplicationRate(). There should be a partial implementation already there
- Finish polishing and testing, then do the full release.

## 1.9.9-beta
- Functions that rely on .Start will yield until started

## 1.9.8-beta
- Switched for loops to be generics for consistency. This should help performance.
- Switched time limit to be .5 milliseconds
- Fixed Bridge:Destroy()?
- Type improvements

## 1.9.7-beta
- BridgeNet.Started has been added
- Middleware fixes. Should be stable now

## 1.8.7-beta
- Hotfix for ClientObject:Fire()

## 1.8.6-beta
- You can now pass nil as parameters

## 1.8.5-beta
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

## 1.7.5-beta
- Improved typings for both ts and luau
- Re-added :Once()
- Updated dependency versions

## 1.6.5-beta
- Fixed invokes
- Added documentation for invokes
- Added .CreateBridgesFromDictionary()
- Significantly improved / fixed roblox-ts typings

## 1.5.5-beta
- Added "RemoteFunction"-type API
	- Added ServerBridge:OnInvoke(function() end)
	- Added ClientBridge:InvokeServerAsync(), yields.
	- Added ClientBridge:InvokeServer(), returns a promise instead of yielding.
- Refactored some code to be better-organized.
- Refactored project structure / testing code to allow for dependencies
- Added Promise as a dependency
- Added GoodSignal as a dependency

## 1.4.5-beta
- Ported to typescript!

## 1.4.4-beta
- You no longer need to declare DefaultReceive and DefaultSend- they default to 60.
- Fixed ServerBridge:Destroy()
- Added print message while waiting for the ClientBridge to be replicated
- Removed the print statement in OnClientEvent. oops!

## 1.4.3-beta
- Removed .FromBridge, use .WaitForBridge or .CreateBridge (createbridge returns the existing bridge object if it exists)
- Configuration object now uses symbols instead of regular strings
- Added global custom logging support. UNSTABLE, DONT USE IN PRODUCTION
- Changed some loops to use ipairs instead of pairs
- Used table.clear instead of tbl = {} for better efficiency
- Fixed Disconnect
- Optimizations (thank you @Baileyeatspizza)
- Fixed ClientBridge breaking if the client's bridge was created before the server created the bridge (thank you evanchan0819)
- Fixed client-to-server communication only sending the first argument

## 0.4.3-alpha
- Connections now spawn a thread, making them yield-safe and error-proof.
- Added .WaitForBridge()
- Added Roact's Symbol class- not used for now, will be used for .Start configuration in the future.
- .CreateBridge() now has the same functionality of .FromBridge()
- Server now checks for the BridgeObject to exist before trying to run connections. If it doesn't exist, nothing happens.

## 0.3.3-alpha
- Hotfix for .CreateIdentifier()

## 0.3.2-alpha
- Connections now use pairs instead of ipairs

## 0.3.1-alpha
- Better error handling / messages
- Removed unused function in ServerBridge/ClientBridge.
- Added .CreateUUID(), .PackUUID(), .UnpackUUID(). (ty Pyseph!)
- Added .DictionaryToTable(), which converts a dictionary into an alphabetically-ordered table.
- Switched .ChildAdded for the client's serdeLayer to be in serdeLayer._start()
- Switched "Network" documentation to be "BridgeNet"- Network was a working title.
- Removed one_remote_event from config.

## 0.2.1-alpha
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