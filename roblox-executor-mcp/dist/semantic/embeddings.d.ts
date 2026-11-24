import type { SemanticSettings } from "./settings.js";
export declare class EmbeddingProviderError extends Error {
    constructor(message: string);
}
export declare function embedTexts(settings: SemanticSettings, inputs: string[]): Promise<number[][]>;
export declare function testEmbeddingProvider(settings: SemanticSettings): Promise<{
    provider: SemanticSettings["provider"];
    model: string;
    dimensions: number;
}>;
