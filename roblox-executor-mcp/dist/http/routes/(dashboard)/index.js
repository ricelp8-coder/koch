import fs from "fs";
import path from "path";
import { WS_PORT } from "../../../config.js";
import { assetsDir } from "../../paths.js";
const htmlPath = path.join(assetsDir, "dashboard", "index.html");
let cachedHtml = null;
function loadHtml() {
    if (cachedHtml !== null)
        return cachedHtml;
    const raw = fs.readFileSync(htmlPath, "utf-8");
    cachedHtml = raw.replace(/\{\{WS_PORT\}\}/g, String(WS_PORT));
    return cachedHtml;
}
export function GET(_req, res) {
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    res.end(loadHtml());
}
