import { getServerLogs, clearServerLogs } from "../../server-logs.js";
export function GET(_req, res, url) {
    const limit = parseInt(url.searchParams.get("limit") || "100", 10);
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ logs: getServerLogs(limit) }));
}
export function DELETE(_req, res) {
    clearServerLogs();
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ ok: true }));
}
