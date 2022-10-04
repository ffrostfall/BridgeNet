import type SerdesLayer from './SerdesLayer';
import serverBridge from './ServerBridge';
import clientBridge from './ClientBridge';

interface BridgeNet {
	CreateUUID: SerdesLayer.CreateUUID;
	PackUUID: SerdesLayer.PackUUID;
	UnpackUUID: SerdesLayer.UnpackUUID;
	DictionaryToTable: SerdesLayer.DictionaryToTable;

	Identifiers: SerdesLayer.Identifiers;
	
	GetQueue: () => {unknown};
	
	CreateBridge: <inbound extends Array <unknown>, outbound extends Array<unknown>>() => serverBridge<inbound, outbound> | clientBridge<inbound, outbound>
}

export = BridgeNet;
