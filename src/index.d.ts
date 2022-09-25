import type ClientBridge from './ClientBridge';
import type ServerBridge from './ServerBridge';
import type SerdesLayer from './SerdesLayer';

type BridgeDictionary = {
	string: [BridgeDictionary] | ClientBridge.CreateBridge | ServerBridge.CreateBridge
}

type StringDictionary = {
	string: string | StringDictionary
}

interface BridgeNet {
	CreateUUID: SerdesLayer.CreateUUID;
	PackUUID: SerdesLayer.PackUUID;
	UnpackUUID: SerdesLayer.UnpackUUID;
	DictionaryToTable: SerdesLayer.DictionaryToTable;

	GetQueue: () => {unknown};
	
	CreateBridge: ClientBridge.CreateBridge | ServerBridge.CreateBridge;
}

export = BridgeNet;
