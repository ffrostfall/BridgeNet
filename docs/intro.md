---
sidebar_position: 1
---

# BridgeNet

BridgeNet is a networking library that solves a multitude of annoyances and problems when working directly with RemoteEvents, while remaining performant
and not losing the ability to easily debug. BridgeNet takes a philosophy of letting the developer optimize what's sent over the wire, while optimizing the calls itself,
trying to be as non-intrusive as possible.

## Features
- A multitude of utility functions such as ``:FireAllInRange()``, ``:FireAllExcept``, and ``:FireAllInRangeExcept``.
- Directly cutting down the amount of data it takes to call a remote event
- Easy-to-use, dynamic serialization/deserialization layer
- Dynamic send/receive rates
- Dynamically creating RemoteEvents while keeping all the above features

## Upcoming features (order = priority)
- Support for rate limiting and middleware
- Typechecking
- Easy logging support
- RemoteFunction-esque functions (this would support promises)
- Using attributes instead of value objects

## Prior art
- RbxNet
- This is a continuation of my previous networking system [NetworkObject](https://devforum.roblox.com/t/networkobject-a-light-weight-network-module-usable-for-everyone/1526416)
- This [devforum post](https://devforum.roblox.com/t/ore-one-remote-event/569721/25) by Tomarty