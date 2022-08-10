# Changelog
Versions are formatted in [semver](https://semver.org/spec/v2.0.0.html).

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