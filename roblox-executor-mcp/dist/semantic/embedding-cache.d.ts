export declare const SEMANTIC_EMBEDDINGS_PATH: string;
export declare function readPersistedEmbedding(key: string): Promise<number[] | undefined>;
export declare function writePersistedEmbeddings(vectors: {
    key: string;
    embedding: number[];
}[]): Promise<void>;
export declare function clearPersistedEmbeddings(): Promise<void>;
