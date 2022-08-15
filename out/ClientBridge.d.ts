declare class ClientObject {
	Fire: (...arguments: any) => undefined
	Connection: (callback: (...arguments: any) => never) => undefined
	Destroy: () => null
}

declare namespace ClientBridge {
	export type CreateBridge = (name: string) => ClientObject
	export type WaitForBridge = (name: string) => ClientObject
}

export = ClientBridge