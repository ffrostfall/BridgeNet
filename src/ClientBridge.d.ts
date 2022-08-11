declare class ClientObject {
	Fire: (...arguments: any) => undefined
	Connection: ((...arguments: any)=>null) => null
	Destroy: () => null
}

interface ClientBridge {
	new: (remoteName: string) => ClientObject
	waitForBridge: () => ClientObject
}

declare const ClientBridge: ClientBridge

export = ClientBridge