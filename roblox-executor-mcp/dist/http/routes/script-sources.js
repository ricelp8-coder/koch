import { getClientById } from "../../bridge/handlers/shared/registry.js";
import { upsertScriptSources, } from "../../bridge/handlers/shared/script-source-store.js";
import { readJsonBody } from "../body.js";
export async function POST(req, res) {
    try {
        const body = await readJsonBody(req);
        const client = body.clientId ? getClientById(body.clientId) : undefined;
        if (!body.clientId || !client) {
            res.writeHead(404);
            res.end("Unknown clientId");
            return;
        }
        const index = upsertScriptSources({
            clientId: client.clientId,
            placeId: client.placeId,
            jobId: client.jobId,
        }, body);
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({
            ok: true,
            mappedSources: index.mappedSources,
            processedSources: index.processedSources,
            skippedSources: index.skippedSources,
            sourcesToMap: index.sourcesToMap,
            hasFinishedMapping: index.hasFinishedMapping,
        }));
    }
    catch {
        res.writeHead(400);
        res.end("Invalid JSON");
    }
}
