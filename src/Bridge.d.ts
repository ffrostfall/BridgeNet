import clientBridge from 'ClientBridge';
import serverBridge from 'ServerBridge';

type config = {
	ReplicationRate?: number,
	AllowsNil?: boolean,
	Client: {
		InboundMiddleware?: Array<(previous: unknown) => unknown>
		OutboundMiddleware?: Array<(previous: unknown) => unknown>
	},
	Server: {
		InboundMiddleware?: Array<(previous: unknown) => unknown>
		OutboundMiddleware?: Array<(previous: unknown) => unknown>
	}
}

type bridgeconf = <inbound extends unknown[], outbound extends unknown[]> (config: config) => clientBridge<inbound, outbound> | serverBridge<inbound, outbound>

export = bridgeconf