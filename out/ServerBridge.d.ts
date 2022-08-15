declare class ServerObject {
	FireTo: (Player: Player, ...arguments: any) => null;
	FireToMultiple: (Players: {Player}, ...arguments: any) => null;
	FireAll: (...arguments: any) => null;
	FireAllInRange: (point: Vector3, range: number, ...arguments: any) => { Player };
	FireAllInRangeExcept: (blacklistedPlayers: {Player}, point: Vector3, range: number, ...arguments: any) => { Player };
	Connection: (callback: (...arguments: any) => never) => undefined
}

declare namespace ServerBridge {
	export type CreateBridge = (name: string) => ServerObject
	export type WaitForBridge = (name: string) => ServerObject
}

export = ServerBridge