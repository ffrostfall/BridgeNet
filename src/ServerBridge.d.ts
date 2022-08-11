// Temporary
type Player = {}
type Vector3 = {}

declare class ServerObject {
	FireTo: (Player: Player, ...arguments: any) => null
	FireToMultiple: (Players: {Player}, ...arguments: any) => null
	FireAll: (...arguments: any) => null
	FireAllInRange: (point: Vector3, range: number, ...arguments: any) => { Player }
	FireAllInRangeExcept: (blacklistedPlayers: {Player}, point: Vector3, range: number, ...arguments: any) => { Player }
	Connection: (Function: (plr: Player,...arguments: any) => never) => undefined
}

interface ServerBridge {
	new: (remoteName: string) => ServerObject
	waitForBridge: (remoteName: string) => ServerObject
}

declare const ServerBridge: ServerBridge

export = ServerBridge