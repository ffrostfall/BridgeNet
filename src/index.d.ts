import type ClientBridge from './ClientBridge';
import type ServerBridge from './ServerBridge';
import type { default as DefaultReceive } from './ConfigSymbols/DefaultReceive';
import type { default as DefaultSend } from './ConfigSymbols/DefaultSend';
import type { default as PrintRemotes } from './ConfigSymbols/PrintRemotes';
import type { default as ReceiveLogsFunction } from './ConfigSymbols/ReceiveLogsFunction';
import type { default as serdeLayer } from './serdeLayer';
import type { default as rateManager } from './rateManager';

type StartOptions = {
	[DefaultReceive]: number | null;
	[DefaultSend]: number | null;
	[PrintRemotes]: boolean | null;
	[ReceiveLogsFunction]: (...any) => undefined | null;
};

interface BridgeNet {
	GetReceiveRate: rateManager.GetReceiveRate;
	SetReceiveRate: rateManager.SetReceiveRate;
	GetSendRate: rateManager.GetSendRate;
	SetSendRate: rateManager.SetSendRate;

	CreateUUID: serdeLayer.CreateUUID;
	PackUUID: serdeLayer.PackUUID;
	UnpackUUID: serdeLayer.UnpackUUID;

	DictionaryToTable: serdeLayer.DictionaryToTable;

	CreateBridgesFromDictionary: (inputObject: {string: ClientBridge.CreateBridge | ServerBridge.CreateBridge | { any: any }}) => { string: {string: {any: any}} | ClientBridge.CreateBridge | ServerBridge.CreateBridge };
	CreateBridge: (name: string) => ClientBridge.CreateBridge | ServerBridge.CreateBridge;
	
	Start: (options: StartOptions) => undefined;
}

export = BridgeNet;
