# Changelog
Versions are formatted in [semver](https://semver.org/spec/v2.0.0.html).

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