import { createServer } from "http";
import { WebSocketServer } from "ws";
import { WS_PORT } from "../../../config.js";
import { dispatchHttp, dispatchWs, loadRoutes } from "../../../http/router.js";
import { resetPrimaryState, setInstanceRole, } from "../shared/communication.js";
import { resetRegistry } from "../shared/registry.js";
export async function startAsPrimary() {
    await loadRoutes();
    return new Promise((resolve, reject) => {
        setInstanceRole("primary");
        resetRegistry();
        resetPrimaryState();
        const httpServer = createServer((req, res) => {
            void dispatchHttp(req, res);
        });
        httpServer.on("error", (err) => {
            if (err.code === "EADDRINUSE") {
                reject(err);
            }
            else {
                console.error("[Primary] HTTP server error:", err);
                reject(err);
            }
        });
        httpServer.listen(WS_PORT, () => {
            console.error(`[Primary] MCP Bridge listening on port ${WS_PORT} (WebSocket + HTTP)`);
            const wss = new WebSocketServer({ server: httpServer });
            wss.on("connection", (ws, req) => dispatchWs(ws, req));
            resolve();
        });
    });
}
