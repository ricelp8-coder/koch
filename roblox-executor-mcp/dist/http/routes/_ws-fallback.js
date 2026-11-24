import { handleRobloxResponse } from "../../bridge/handlers/shared/communication.js";
import { getClientIdByWs, registerClient, unregisterClient, } from "../../bridge/handlers/shared/registry.js";
export function WS(ws) {
    console.error("[Primary] Roblox client connected via WebSocket (awaiting registration).");
    ws.on("message", (rawData) => {
        try {
            const data = JSON.parse(rawData.toString());
            if (data.type === "register") {
                const info = data;
                const clientId = registerClient({
                    username: info.username || "Unknown",
                    userId: info.userId || 0,
                    placeId: info.placeId || 0,
                    jobId: info.jobId || "",
                    placeName: info.placeName || "Unknown",
                    transport: "ws",
                    ws,
                });
                ws.send(JSON.stringify({ type: "registered", clientId }));
                return;
            }
            handleRobloxResponse(data);
        }
        catch (e) {
            console.error("[Primary] Error parsing Roblox WS message:", e);
        }
    });
    ws.on("close", () => {
        const clientId = getClientIdByWs(ws);
        if (clientId)
            unregisterClient(clientId);
        console.error("[Primary] Roblox client disconnected.");
    });
}
