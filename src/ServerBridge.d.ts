declare class Connection {
	Disconnect(): void
}

declare class serverBridge<inbound extends Array<unknown>, outbound extends Array<unknown>> {
    FireTo: (Player: Player, ...arguments: outbound) => void;
    FireToMultiple: (Players: Array<Player>, ...arguments: outbound) => void;
    FireAll: (...arguments: outbound) => void;
    FireAllInRange: (point: Vector3, range: number, ...arguments: outbound) => Array<Player>;
    FireAllInRangeExcept: (blacklistedPlayers: Array<Player>, point: Vector3, range: number, ...arguments: outbound) => Array<Player>;
    Connection: (callback: (...arguments: inbound) => never) => Connection;
    OnInvoke: (callback: (plr: Player, ...arguments: inbound) => void) => void;
    SetReplicationRate: (rate: number) => void;
	SetOutboundMiddleware(middleware: Array<(previous: unknown) => unknown>): void
    SetInboundMiddleware(middleware: Array<(previous: unknown) => unknown>): void
	SetNilAllowed(allowed: boolean): void
}

export = serverBridge