import fs from "fs";
import path from "path";
import { assetsDir } from "../../paths.js";
const assetPath = path.join(assetsDir, "dashboard", "dashboard.js");
let cached = null;
export function GET(_req, res) {
    if (cached === null)
        cached = fs.readFileSync(assetPath, "utf-8");
    res.writeHead(200, {
        "Content-Type": "application/javascript; charset=utf-8",
    });
    res.end(cached);
}
