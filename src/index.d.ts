import type ClientBridge from './ClientBridge';
import type ServerBridge from './ServerBridge';
import type SerdesLayer from './SerdesLayer';

interface BridgeNet {
	CreateUUID: SerdesLayer.CreateUUID;
	PackUUID: SerdesLayer.PackUUID;
	UnpackUUID: SerdesLayer.UnpackUUID;
	DictionaryToTable: SerdesLayer.DictionaryToTable;

	GetQueue: () => {unknown};
	
	ReplicationStep: (replicationRate: number, callback: () => void) => void;
	
	CreateBridge: ClientBridge.CreateBridge | ServerBridge.CreateBridge;
}

export = BridgeNet;
