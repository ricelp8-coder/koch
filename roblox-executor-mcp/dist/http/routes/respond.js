import { handleRobloxResponse } from "../../bridge/handlers/shared/communication.js";
import { readJsonBody } from "../body.js";
export async function POST(req, res) {
    try {
        const data = await readJsonBody(req);
        handleRobloxResponse(data);
        res.writeHead(200);
        res.end("OK");
    }
    catch {
        res.writeHead(400);
        res.end("Invalid JSON");
    }
}
