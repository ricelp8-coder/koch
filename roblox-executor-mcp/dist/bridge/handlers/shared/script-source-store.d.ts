export interface StoredScriptSource {
    debugId: string;
    path: string;
    source: string;
    sourceHash: string;
    updatedAt: number;
}
export interface ScriptSourceIndex {
    clientId: string;
    placeId: number;
    jobId: string;
    hasFinishedMapping: boolean;
    mappedSources: number;
    processedSources: number;
    skippedSources: number;
    sourcesToMap: number;
    scripts: StoredScriptSource[];
}
export interface ScriptSourceStoreIdentity {
    clientId: string;
    placeId: number;
    jobId: string;
}
export interface UpsertScriptSourcesInput {
    hasFinishedMapping?: boolean;
    sourcesToMap?: number;
    processedSources?: number;
    skippedSources?: number;
    scripts?: {
        debugId?: unknown;
        path?: unknown;
        source?: unknown;
    }[];
}
export declare function upsertScriptSources(identity: ScriptSourceStoreIdentity, input: UpsertScriptSourcesInput): ScriptSourceIndex;
export declare function getScriptSourceIndex(identity: ScriptSourceStoreIdentity): ScriptSourceIndex;
export declare function clearScriptSourceIndex(clientId: string): void;
