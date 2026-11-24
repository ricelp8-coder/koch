import { registerClient } from "../../bridge/handlers/shared/registry.js";
import { readJsonBody } from "../body.js";
export async function POST(req, res) {
    try {
        const info = await readJsonBody(req);
        const clientId = registerClient({
            username: info.username || "Unknown",
            userId: info.userId || 0,
            placeId: info.placeId || 0,
            jobId: info.jobId || "",
            placeName: info.placeName || "Unknown",
            transport: "http",
        });
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ clientId }));
    }
    catch {
        res.writeHead(400);
        res.end("Invalid JSON");
    }
}
