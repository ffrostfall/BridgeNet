/// <reference types="@rbxts/types" />

type QueueSendPacket = {
    plrs: string | Player | Array<Player>;
    remote: string;
    args: Array<any>;
    replRate: number;
    invokeReply?: any;
    uuid?: string;
};

type QueueReceivePacket = {
    plr: Player;
    remote: string;
    args: Array<any>;
};

type SendQueue = Array<QueueSendPacket>;
type ReceiveQueue = Array<QueueReceivePacket>;

interface Connection {
    Disconnect(): void;
}

interface Bridge {
    GetName(): string;

    SetReplicationRate(rate: string): void;

    Connect(callback: (...args: Array<unknown>) => void): Connection;
    Once(callback: (...args: Array<unknown>) => void): void;

    Destroy(): void;
}

export interface ServerBridge extends Bridge {
    FireTo(plr: Player, ...args: any): void;
    FireToMultiple(players: Array<Player>, ...args: any): void;
    FireToAllExcept(
        blacklist: Player | Array<Player>,
        ...args: any
    ): Array<Player>;
    FireAll(...args: any): void;
}

export interface ClientBridge extends Bridge {
    Fire(...args: any): void;

    SetNilAllowed(allowed: boolean): void;
}

export namespace BridgeNet {
    export function CreateBridge(name: string): ServerBridge | ClientBridge;
    export function Identifiers(ids: Array<string>): {
        [index in keyof typeof ids]: string;
    };

    export function GetQueue(): LuaTuple<[SendQueue, ReceiveQueue]>;

    // SerdesLayer
    export function CreateIdentifier(id: string): string;
    export function DestroyIdentifier(id: string): void;
    export function CreateUUID(): string;
    export function PackUUID(uuid: string): string;
    export function UnpackUUID(packed: string): string;

    export function DictionaryToTable<T>(dict: {
        [index: string]: T;
    }): Array<T>;
}
