import { GetResponseOfIdFromClient, SendArbitraryDataToClient, } from "../../../bridge/handlers/shared/communication.js";
import { resolveTargetClient, setActiveClientId, } from "../../../bridge/handlers/shared/registry.js";
import { getScriptSourceIndex, } from "../../../bridge/handlers/shared/script-source-store.js";
import { loadSemanticSettings, validateSemanticSettings } from "../../../semantic/settings.js";
import { semanticIndexCodebase, semanticSearchScripts } from "../../../semantic/vector-index.js";
import { completeProgressJob, createProgressJob, failProgressJob, updateProgressJob, } from "../../../semantic/progress.js";
import { readJsonBody } from "../../body.js";
function jsonOk(res, data) {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(data));
}
function jsonErr(res, error) {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error }));
}
function formatSemanticSearchResult(query, searchResults, chunkCount, embeddedChunks, isPartialIndex) {
    const parts = [];
    if (isPartialIndex) {
        const pct = chunkCount > 0 ? Math.round((embeddedChunks / chunkCount) * 100) : 0;
        parts.push(`⚠️ WARNING: The codebase is NOT fully indexed. Only ${embeddedChunks}/${chunkCount} chunks (${pct}%) have embeddings. Results may be incomplete.`);
    }
    const header = `${searchResults.length} match(es) for "${query}" across ${chunkCount} chunks`;
    parts.push(header);
    const body = searchResults.map((r, i) => `${i + 1}. [${r.path}] lines ${r.startLine}-${r.endLine} (score ${r.score.toFixed(4)})\n\n${r.snippet}`).join("\n\n---\n\n");
    if (body)
        parts.push(body);
    return parts.join("\n\n");
}
function formatSemanticIndexResult(chunkCount, embeddedChunks) {
    return `Semantic index ready: ${embeddedChunks}/${chunkCount} chunks embedded.`;
}
export async function POST(req, res) {
    try {
        const body = await readJsonBody(req);
        const { type, clientId, ...params } = body;
        if (!type)
            return jsonErr(res, "Missing 'type' field.");
        // Resolve target client
        const target = resolveTargetClient(clientId);
        if (!target)
            return jsonErr(res, "No active client found.");
        // Set active client for this request
        if (clientId)
            setActiveClientId(clientId);
        // ── Script Grep (server-side search) ──────────────────────────────────────
        if (type === "script-grep") {
            const query = params.query;
            if (!query)
                return jsonErr(res, "Missing 'query' parameter.");
            const index = getScriptSourceIndex({
                clientId: target.clientId,
                placeId: target.placeId,
                jobId: target.jobId,
            });
            if (!index.hasFinishedMapping) {
                return jsonErr(res, `Still receiving script sources (${index.mappedSources}/${index.sourcesToMap}). Try again later.`);
            }
            const literal = params.literal === true;
            const caseSensitive = params.caseSensitive !== false;
            const limit = Math.min(Math.max(Number(params.limit) || 50, 1), 100);
            let regex;
            try {
                const pattern = literal ? query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") : query;
                regex = new RegExp(pattern, caseSensitive ? "" : "i");
            }
            catch (e) {
                return jsonErr(res, `Invalid regex: ${e.message}`);
            }
            const results = [];
            let totalMatches = 0;
            for (const script of index.scripts) {
                if (results.length >= limit)
                    break;
                const lines = script.source.split(/\r?\n/);
                const matches = [];
                for (let i = 0; i < lines.length && matches.length < 20; i++) {
                    if (regex.test(lines[i] ?? "")) {
                        const start = Math.max(0, i - 2);
                        const end = Math.min(lines.length - 1, i + 2);
                        const block = [];
                        for (let j = start; j <= end; j++) {
                            block.push(`${j === i ? ">" : " "} ${j + 1}: ${lines[j] ?? ""}`);
                        }
                        matches.push(block.join("\n"));
                    }
                }
                if (matches.length > 0) {
                    totalMatches += matches.length;
                    results.push({
                        path: script.path || `<ScriptProxy: ${script.debugId}>`,
                        matches,
                    });
                }
            }
            const header = `${totalMatches} match(es) across ${results.length} script(s)`;
            const body = results.map(r => `[${r.path}] ${r.matches.length} match(es)\n\n${r.matches.join("\n\n")}`).join("\n\n---\n\n");
            return jsonOk(res, { result: header + (body ? "\n\n" + body : "") });
        }
        // ── Semantic Search (server-side) ─────────────────────────────────────────
        if (type === "semantic-search") {
            const query = params.query;
            if (!query)
                return jsonErr(res, "Missing 'query' parameter.");
            const index = getScriptSourceIndex({
                clientId: target.clientId,
                placeId: target.placeId,
                jobId: target.jobId,
            });
            if (index.scripts.length === 0) {
                return jsonErr(res, `No script sources have been received yet.`);
            }
            const settings = await loadSemanticSettings();
            const settingsError = validateSemanticSettings(settings);
            if (settingsError)
                return jsonErr(res, `Semantic search not configured: ${settingsError}`);
            const limit = Math.min(Math.max(Number(params.limit) || 10, 1), 50);
            const indexOnly = params.indexOnly === true;
            const job = createProgressJob(indexOnly ? "semantic-index" : "semantic-search", indexOnly ? "Starting semantic index" : "Starting semantic search");
            void (async () => {
                try {
                    if (indexOnly) {
                        const { chunkCount, embeddedChunks } = await semanticIndexCodebase(index, settings, (progress) => updateProgressJob(job.id, progress));
                        completeProgressJob(job.id, formatSemanticIndexResult(chunkCount, embeddedChunks));
                        return;
                    }
                    const output = await semanticSearchScripts(index, settings, query, limit, undefined, (progress) => updateProgressJob(job.id, progress));
                    completeProgressJob(job.id, formatSemanticSearchResult(query, output.results, output.chunkCount, output.embeddedChunks, output.isPartialIndex));
                }
                catch (error) {
                    failProgressJob(job.id, error instanceof Error ? error.message : String(error));
                }
            })();
            return jsonOk(res, { jobId: job.id, progressUrl: `/api/tool-progress?id=${job.id}` });
        }
        // ── Get Script Content (server-side index + client fallback) ───────────────
        if (type === "get-script-content") {
            const scriptPath = params.scriptPath;
            const scriptGetterSource = params.scriptGetterSource;
            const startLine = params.startLine;
            const endLine = params.endLine;
            if (!scriptPath && !scriptGetterSource)
                return jsonErr(res, "Missing 'scriptPath' or 'scriptGetterSource'.");
            const scriptProxyMatch = (scriptPath ?? scriptGetterSource ?? "").match(/^<ScriptProxy: (.+)>$/);
            // Try server-side index first
            if (scriptPath) {
                const index = getScriptSourceIndex({
                    clientId: target.clientId,
                    placeId: target.placeId,
                    jobId: target.jobId,
                });
                const stored = index.scripts.find((s) => scriptProxyMatch ? s.debugId === scriptProxyMatch[1] : s.path === scriptPath);
                if (stored) {
                    let source = stored.source;
                    if (startLine !== undefined) {
                        const lines = source.split(/\r?\n/);
                        const total = lines.length;
                        const start = Math.max(1, Math.min(Math.floor(startLine), total));
                        const end = endLine === undefined ? total : Math.max(start, Math.min(Math.floor(endLine), total));
                        source = `-- Lines ${start}-${end} of ${total}\n` + lines.slice(start - 1, end).join("\n");
                    }
                    return jsonOk(res, { result: source });
                }
            }
            // Fall back to dispatching to Roblox client
            const data = scriptProxyMatch
                ? { debugId: scriptProxyMatch[1], startLine, endLine }
                : {
                    source: scriptGetterSource === undefined ? `return ${scriptPath}` : scriptGetterSource,
                    startLine,
                    endLine,
                };
            const callId = SendArbitraryDataToClient("get-script-content", data, undefined, target.clientId);
            if (!callId)
                return jsonErr(res, "Failed to dispatch to client.");
            if (callId === "INVALID_CLIENT")
                return jsonErr(res, "Invalid client.");
            const response = await GetResponseOfIdFromClient(callId, 15000);
            if (response.error)
                return jsonOk(res, { result: `Error: ${response.error}` });
            return jsonOk(res, { result: response.output ?? "No output returned." });
        }
        // ── Client-dispatched tools ───────────────────────────────────────────────
        const dispatchTypes = {
            "get-data-by-code": "get-data-by-code",
            "execute": "execute",
            "search-instances": "search-instances",
            "get-console-output": "get-console-output",
            "get-descendants-tree": "get-descendants-tree",
            "get-game-info": "get-game-info",
        };
        const robloxType = dispatchTypes[type];
        if (!robloxType)
            return jsonErr(res, `Unknown tool type: ${type}`);
        // Build data for the client
        const data = {};
        if (type === "get-data-by-code") {
            const code = params.code;
            if (!code)
                return jsonErr(res, "Missing 'code' parameter.");
            const timeout = Math.min(Math.max(Number(params.timeout) || 15000, 1000), 120000);
            data.source = `setthreadidentity(8);${code}`;
            const callId = SendArbitraryDataToClient(robloxType, data, undefined, target.clientId);
            if (!callId)
                return jsonErr(res, "Failed to dispatch to client.");
            if (callId === "INVALID_CLIENT")
                return jsonErr(res, "Invalid client.");
            const response = await GetResponseOfIdFromClient(callId, timeout);
            if (response.error)
                return jsonOk(res, { result: `Error: ${response.error}` });
            return jsonOk(res, { result: response.output ?? "No output returned." });
        }
        if (type === "execute") {
            const code = params.code;
            if (!code)
                return jsonErr(res, "Missing 'code' parameter.");
            data.source = `setthreadidentity(8);${code}`;
            const callId = SendArbitraryDataToClient(robloxType, data, undefined, target.clientId);
            if (!callId)
                return jsonErr(res, "Failed to dispatch to client.");
            if (callId === "INVALID_CLIENT")
                return jsonErr(res, "Invalid client.");
            return jsonOk(res, { result: "Code dispatched to client." });
        }
        if (type === "search-instances") {
            const selector = params.selector;
            if (!selector)
                return jsonErr(res, "Missing 'selector' parameter.");
            data.selector = selector;
            data.root = params.root || "game";
            data.limit = Math.min(Number(params.limit) || 50, 100);
        }
        else if (type === "get-console-output") {
            data.limit = Math.min(Number(params.limit) || 50, 200);
            if (typeof params.logsOrder === "string")
                data.logsOrder = params.logsOrder;
            if (typeof params.filter === "string")
                data.filter = params.filter;
        }
        else if (type === "get-descendants-tree") {
            const root = params.root;
            if (!root)
                return jsonErr(res, "Missing 'root' parameter.");
            data.root = root;
            data.maxDepth = Math.min(Number(params.maxDepth) || 3, 10);
            if (params.classFilter)
                data.classFilter = params.classFilter;
        }
        const callId = SendArbitraryDataToClient(robloxType, data, undefined, target.clientId);
        if (!callId)
            return jsonErr(res, "Failed to dispatch to client.");
        if (callId === "INVALID_CLIENT")
            return jsonErr(res, "Invalid client.");
        const response = await GetResponseOfIdFromClient(callId, 15000);
        if (response.error)
            return jsonOk(res, { result: `Error: ${response.error}` });
        return jsonOk(res, { result: response.output ?? "No output returned." });
    }
    catch (err) {
        jsonErr(res, `Tool execution failed: ${err.message || err}`);
    }
}
