import { type ScriptSourceIndex, type StoredScriptSource } from "../../../bridge/handlers/shared/script-source-store.js";
import type { ToolTextResponse } from "../../factory.js";
export type ScriptSearchDocument = StoredScriptSource;
export type ScriptSearchIndex = ScriptSourceIndex;
export type ScriptSearchIndexResult = {
    ok: true;
    index: ScriptSearchIndex;
} | {
    ok: false;
    response: ToolTextResponse;
};
export declare function fetchScriptSearchIndex(options?: {
    allowIncomplete?: boolean;
}): ScriptSearchIndexResult;
