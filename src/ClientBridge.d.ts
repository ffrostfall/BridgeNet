declare class Connection {
	Disconnect(): void
}

declare class clientBridge<inbound extends Array<unknown>, outbound extends Array<unknown>> {
	Fire(...outbound: outbound): void
	Connect(...inbound: inbound): Connection
	Once(...inbound: inbound): void
	InvokeServerAsync(arguments): unknown
	SetReplicationRate(replicationRate: number): void
	SetNilAllowed(allowed: boolean): void
	SetOutboundMiddleware(middleware: Array<(previous: unknown) => unknown>): void
	SetInboundMiddleware(middleware: Array<(previous: unknown) => unknown>): void
	Destroy(): void
}

export = clientBridge