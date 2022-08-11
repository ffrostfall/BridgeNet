import type ClientBridge from './ClientBridge';
import type ServerBridge from './ServerBridge';
import type { default as DefaultReceive } from './ConfigSymbols/DefaultReceive';
import type { default as DefaultSend } from './ConfigSymbols/DefaultSend';
import type { default as PrintRemotes } from './ConfigSymbols/PrintRemotes';
import type { default as ReceiveLogsFunction } from './ConfigSymbols/ReceiveLogsFunction';
import type { default as serdeLayer } from './serdeLayer';
import type { default as rateManager } from './rateManager';

type StartOptions = {
	[DefaultReceive]: number;
	[DefaultSend]: number;
	[PrintRemotes]: boolean;
	[ReceiveLogsFunction]: (...any) => undefined;
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

	Start: (options: StartOptions) => undefined;
}

export = BridgeNet;
