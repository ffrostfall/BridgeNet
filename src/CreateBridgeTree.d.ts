import bridge from 'Bridge';

type Dictionary<V> = {[string: string]: V}
type TreeLeaf = Dictionary<bridge>
type Tree = Dictionary<bridge | Dictionary<TreeLeaf>>

type CreateBridgeTree = (tree: Tree) => keyof typeof tree