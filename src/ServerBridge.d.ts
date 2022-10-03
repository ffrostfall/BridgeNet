declare class ServerObject<T extends Array<unknown>> {
    FireTo: (Player: Player, ...arguments: T) => void;
    FireToMultiple: (Players: Array<Player>, ...arguments: T) => void;
    FireAll: (...arguments: T) => void;
    FireAllInRange: (point: Vector3, range: number, ...arguments: T) => Array<Player>;
    FireAllInRangeExcept: (blacklistedPlayers: Array<Player>, point: Vector3, range: number, ...arguments: T) => Array<Player>;
    Connection: (callback: (...arguments: T) => never) => void;
    OnInvoke: (callback: (plr: Player, ...arguments: T) => void) => void;
    SetReplicationRate: (rate: number) => void;
	SetOutboundMiddleware(middleware: Array<(previous: unknown) => unknown>): void
    SetInboundMiddleware(middleware: Array<(previous: unknown) => unknown>): void
	SetNilAllowed(allowed: boolean): void
}

declare class Connection {
	Disconnect(): void
}

declare class clientBridge<inbound, outbound> {
	Fire(outbound: outbound): void
	Connect(inbound: inbound): Connection
	Once(inbound: inbound): void
	InvokeServerAsync<returnType>(arguments: Array<unknown>): returnType
	SetReplicationRate(replicationRate: number): void
	SetNilAllowed(allowed: boolean): void
	SetOutboundMiddleware(middleware: Array<(previous: unknown) => unknown>): void
	SetInboundMiddleware(middleware: Array<(previous: unknown) => unknown>): void
	Destroy(): void
}

export = ServerObject