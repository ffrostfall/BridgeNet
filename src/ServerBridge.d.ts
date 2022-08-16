declare class ServerObject<T extends Array<unknown>> {
    FireTo: (Player: Player, ...arguments: T) => void;
    FireToMultiple: (Players: Array<Player>, ...arguments: T) => void;
    FireAll: (...arguments: T) => void;
    FireAllInRange: (point: Vector3, range: number, ...arguments: T) => Array<Player>;
    FireAllInRangeExcept: (blacklistedPlayers: Array<Player>, point: Vector3, range: number, ...arguments: T) => Array<Player>;
    Connection: (callback: (...arguments: T) => never) => void;
    OnInvoke: (callback: (plr: Player, ...arguments: T) => void) => void;
}

declare namespace ServerBridge {
	export type CreateBridge = <T extends Array<unknown>>(name: string) => ServerObject<T>
	export type WaitForBridge = <T extends Array<unknown>>(name: string) => ServerObject<T>
}

export = ServerBridge