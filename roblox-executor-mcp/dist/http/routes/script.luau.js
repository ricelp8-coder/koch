import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CONNECTOR_PATH = path.resolve(__dirname, "../../../connector.luau");
export async function GET(_req, res) {
    try {
        const source = await fs.readFile(CONNECTOR_PATH, "utf8");
        res.writeHead(200, {
            "Content-Type": "text/plain; charset=utf-8",
            "Cache-Control": "no-store",
        });
        res.end(source);
    }
    catch (error) {
        console.error("[script.luau] Failed to read connector:", error);
        res.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
        res.end("Failed to load connector.luau");
    }
}
