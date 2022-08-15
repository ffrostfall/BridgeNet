declare namespace rateManager {
	export type SetReceiveRate = (toSet: number) => null
	export type GetReceiveRate = () => number
	export type SetSendRate = (toSet: number) => null
	export type GetSendRate = () => number
}

export = rateManager