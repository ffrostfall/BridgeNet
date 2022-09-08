<img width="128" src="https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/4X/1/4/6/14624c95fe154206b1290b8172d31cdc06d2f274.png" />

# BridgeNet
Insanely optimized networking library for Roblox, with roblox-ts support.

* [Documentation](https://ffrostflame.github.io/BridgeNet/)
* [Latest release](https://github.com/ffrostflame/BridgeNet/releases) (v1.9.8-beta)
* [BridgeNet on Roblox Marketplace](https://www.roblox.com/library/10494533012/BridgeNet-v1-8-7-beta) (v1.8.7-beta)

BridgeNet is a networking library bundled with features to make optimizations easier, alongside optimizing remote events itself. It also has numerous features such as `:FireAllInRange` and `:FireToMultiple`.

If your game uses BridgeNet, please let me know! The amount of people using BridgeNet helps me realize how battle-tested it is and helps me develop the module. It also helps me know when to fully release!

## Features
* Easy-to-use utility features such as `:FireAllInRange()`, `:FireAllExcept()`, `:FireMultiple()`
* Dynamically create/destroy “remote events” with ease
* Configure the rate of which remotes send and receive information
* Serialization of RemoteEvents for optimization
* Using compressed ID strings to reduce the amount of data each remote call takes, mimicking multiple remote calls.
* Utilities to compress the data you’re sending over such as `.DictionaryToTable`, and `.PackUUID`
* Incredibly easy optimization beyond what’s already provided
* No direct interaction with instances, that’s all abstracted and wrapped away.
* `InvokeServer` (returns a Promise) and `InvokeServerAsync` allow for `RemoteFunction` usability with promises
* roblox-ts support!

## Goals
* Make optimization easy, but manual. Don’t intrude on the developer where they don’t expect it, but give them the tools to optimize.
* Keep a simple and human-readable API while still retaining functionality of other net tools.
* Make all functionality extra - you don’t need to understand middleware in order to use the module, but if you do, you can use middleware.

## Upcoming features
* Middleware and rate limiting. There's internal support right now, but I delayed it for a later date due to some architecture concerns.
* Typechecking

## For contributors
Please add your changes to CHANGELOG.md when you make a PR, it makes it a lot easier on me to make new releases and prevents a lot of confusion.

## Performance

This test was run with 200 blank remote calls sent per frame. In this case, BridgeNet used 42.7% less bandwidth.

**BridgeNet** 63 KB/s average:

<img src="https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/4X/3/1/4/3143289e238ed46e44fb60b50e326d4800232391.png" />

**Roblox** 110 KB/s average:

<img src="https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/4X/c/0/b/c0bafc9c93c7ac48ab48740fe28eed8ae2e145fb.png" />

## Why should I care about the amount of data being sent/received?

Because it's integral to your game's performance. Less data and fewer calls means lower frame times, lower ping, easier for players with packet loss and bad connections, and overall a better experience. 

If you have a player cap on your game of 50, and each player is receiving 100 kilobytes per second, that means your server is sending 5,000 kilobytes per second. 5,000/1,000 (kilobytes in a megabyte) is 5, which means you have 5 megabytes being sent out per second. Now, we all know Roblox servers are suboptimal compared to your average dedicated game server. And 5 megabytes... isn’t that much nowadays, right?

In the networking world, megabits are used to measure things like speed. One megabyte is 8 megabits, and things like speedtest.net use megabits (abbreviated as Mb). So, if your internet upload speed is 40 megabits per second, that means running your computer as a server for your Roblox game would result in your entire bandwith being taken up.

(Take this with a grain of salt. I’m not 100% sure why BridgeNet performs better here) So another thing that BridgeNet does better is ordering. When Roblox sends out packets, it waits to make sure it’s done in the right order. 

I’m pretty sure this is because Roblox orders each remote event individually, so when one doesn’t play nice or gets sent earlier, it stops and waits before resuming networking. So the more RemoteEvents that are fired/received, the higher the probability is it stops and waits. With BridgeNet, since it’s one remote call per frame, this isn’t an issue. Roblox already sends packets out per frame, so the big packets aren’t an issue.

## On the topic of networking, reliablity types are a must

> As a Roblox developer, it is currently impossible to send network messages over anything other than a reliable ordered channel. This is a huge problem for networked game state that needs to be sent very frequently. Re-transmissions and acknowledgements are nice for data that must get there eventually, but it really blows for state that is just going to be immediately sent again in the next network step.
>
>The biggest use case for something like this is custom character replication. We only care about the most recent position and orientation of a replicated character, and we don’t want old stale state to be re-transmitted to us.
>
>I propose adding the property RemoteEvent.Reliability which determines the reliability type of network messages sent using it. This property would be an enum, and could include ReliableOrdered (the way it works now), Unreliable (packets may be dropped), and UnreliableSequenced (same as unreliable, but only the most recent message is accepted).
>
>Being able to send unreliable messages is a bare necessity for creating low-latency multiplayer games. In my opinion this would allow developers to fine tune their games’ networking in order to deliver a more consistent experience.
>
> &mdash; [HaxHelper](https://devforum.roblox.com/t/reliability-types-for-remoteevent/308510)

Due to Roblox’s RemoteEvents being reliable and ordered, it can make systems like head rotation systems cause tons of lag and take up a bunch of unused bandwith. It also means any custom humanoid system like Chickynoid will be less effective than if this feature existed.

This feature would improve the Roblox platform tremendously if added, and I ask you all to support this feature. If this is added, I can assure you BridgeNet will immediately update to have streaming data support.

The lack of this feature is a direct roadblock to many MMOs. It’s one of the biggest roadblocks on the platform right now. Please- take your time and show your support.

