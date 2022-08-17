import type ClientBridge from './ClientBridge';
import type ServerBridge from './ServerBridge';
import type { default as DefaultReceive } from './ConfigSymbols/DefaultReceive';
import type { default as DefaultSend } from './ConfigSymbols/DefaultSend';
import type { default as PrintRemotes } from './ConfigSymbols/PrintRemotes';
import type { default as ReceiveLogFunction } from './ConfigSymbols/ReceiveLogFunction';
import type { default as SendLogFunction } from './ConfigSymbols/SendLogFunction';
import type { default as serdeLayer } from './serdeLayer';
import type { default as rateManager } from './rateManager';

type StartOptions = {
	[DefaultReceive]: number | null;
	[DefaultSend]: number | null;
	[PrintRemotes]: boolean | null;
	[ReceiveLogFunction]: (...args: Array<unknown>) => undefined | null;
	[SendLogFunction]: (...args: Array<unknown>) => undefined | null;
};

type BridgeDictionary = {
	string: [BridgeDictionary] | ClientBridge.CreateBridge | ServerBridge.CreateBridge
}

type StringDictionary = {
	string: string | StringDictionary
}

interface BridgeNet {
	DefaultReceive: typeof DefaultReceive;
	DefaultSend: typeof DefaultSend;
	SendLogFunction: typeof SendLogFunction;
	ReceiveLogFunction: typeof ReceiveLogFunction;
	
	GetReceiveRate: rateManager.GetReceiveRate;
	SetReceiveRate: rateManager.SetReceiveRate;
	GetSendRate: rateManager.GetSendRate;
	SetSendRate: rateManager.SetSendRate;

	CreateUUID: serdeLayer.CreateUUID;
	PackUUID: serdeLayer.PackUUID;
	UnpackUUID: serdeLayer.UnpackUUID;

	DictionaryToTable: serdeLayer.DictionaryToTable;

	CreateBridgesFromDictionary: (StringDictionary) => BridgeDictionary;
	CreateBridge: ClientBridge.CreateBridge | ServerBridge.CreateBridge;
	
	Start: (options: StartOptions) => undefined;
}

export = BridgeNet;
