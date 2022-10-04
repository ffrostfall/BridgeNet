declare namespace serdeLayer {
	export type CreateIdentifier = (identifier: string) => string
	export type DestroyIdentifier = (identifier: string) => null
	export type CreateUUID = () => string
	export type PackUUID = (uuid: string) => string
	export type UnpackUUID = (packedUUID: string) => string
	
	export type DictionaryToTable = <A>(dict: { [index: string]: A }) => Array<A>
	export type Identifiers = (idlist: Array<string>) => keyof typeof Array
}

export = serdeLayer