import type { ScriptSourceIndex } from "../bridge/handlers/shared/script-source-store.js";
import type { SemanticSettings } from "./settings.js";
export interface SemanticSearchResult {
    path: string;
    debugId: string;
    startLine: number;
    endLine: number;
    score: number;
    snippet: string;
}
export interface SemanticSearchProgress {
    message: string;
    completed: number;
    total: number;
}
export declare function getSemanticIndexStats(index: ScriptSourceIndex, settings: SemanticSettings): {
    chunkCount: number;
    embeddedChunks: number;
    uniqueChunkCount: number;
    embeddedUniqueChunks: number;
};
export interface SemanticSearchOutput {
    results: SemanticSearchResult[];
    chunkCount: number;
    embeddedChunks: number;
    isPartialIndex: boolean;
}
export declare function semanticSearchScripts(index: ScriptSourceIndex, settings: SemanticSettings, query: string, limit: number, minScore?: number, onProgress?: (progress: SemanticSearchProgress) => void): Promise<SemanticSearchOutput>;
export declare function semanticIndexCodebase(index: ScriptSourceIndex, settings: SemanticSettings, onProgress?: (progress: SemanticSearchProgress) => void): Promise<{
    chunkCount: number;
    embeddedChunks: number;
}>;
export declare function clearSemanticIndexForClient(clientId: string): void;
export declare function clearAllSemanticIndexes(): void;
export declare function getScriptIndexStatus(debugId: string, index: ScriptSourceIndex, settings: SemanticSettings): {
    totalChunks: number;
    embeddedChunks: number;
    isFullyIndexed: boolean;
};
