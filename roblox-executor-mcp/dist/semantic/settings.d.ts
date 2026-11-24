export type SemanticProvider = "openai" | "ollama";
export interface SemanticSettings {
    provider: SemanticProvider;
    openaiApiKey: string;
    openaiBaseUrl: string;
    openaiModel: string;
    ollamaBaseUrl: string;
    ollamaModel: string;
    saveEmbeddingsToDisk: boolean;
}
export interface PublicSemanticSettings {
    provider: SemanticProvider;
    openaiApiKeySet: boolean;
    openaiApiKeyMasked: string;
    openaiBaseUrl: string;
    openaiModel: string;
    ollamaBaseUrl: string;
    ollamaModel: string;
    saveEmbeddingsToDisk: boolean;
}
export type SemanticSettingsInput = Partial<{
    provider: unknown;
    openaiApiKey: unknown;
    openaiBaseUrl: unknown;
    openaiModel: unknown;
    ollamaBaseUrl: unknown;
    ollamaModel: unknown;
    saveEmbeddingsToDisk: unknown;
}>;
export declare const SEMANTIC_CONFIG_DIR: string;
export declare const SEMANTIC_SETTINGS_PATH: string;
export declare const DEFAULT_SEMANTIC_SETTINGS: SemanticSettings;
export declare function normalizeOllamaBaseUrl(value: unknown, fallback: string): string;
export declare function normalizeOpenAIBaseUrl(value: unknown, fallback: string): string;
export declare function loadSemanticSettings(): Promise<SemanticSettings>;
export declare function saveSemanticSettings(input: SemanticSettingsInput): Promise<SemanticSettings>;
export declare function toPublicSemanticSettings(settings: SemanticSettings): PublicSemanticSettings;
export declare function validateSemanticSettings(settings: SemanticSettings): string | null;
export declare function getSemanticProviderModel(settings: SemanticSettings): string;
