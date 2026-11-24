import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { HTTP_METHODS, } from "./types.js";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const routesDir = path.join(__dirname, "routes");
const httpRoutes = [];
const wsRoutes = [];
let defaultWsHandler = null;
const WS_FALLBACK_NAME = "_ws-fallback";
async function walk(dir) {
    const out = [];
    const entries = await fs.promises.readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            out.push(...(await walk(full)));
        }
        else if (entry.isFile() && entry.name.endsWith(".js")) {
            out.push(full);
        }
    }
    return out;
}
const GROUP_SEGMENT = /^\(.+\)$/;
/**
 * Derive a URL pathname from the file's location under routesDir.
 * Directory segments wrapped in parens — e.g. `(auth)` — are groups and
 * are dropped from the URL, matching Next.js behavior.
 */
function fileToUrlPath(file) {
    const rel = path.relative(routesDir, file);
    const parsed = path.parse(rel);
    const segments = parsed.dir
        ? parsed.dir.split(path.sep).filter((seg) => !GROUP_SEGMENT.test(seg))
        : [];
    const dir = segments.join("/");
    const name = parsed.name;
    if (!dir && name === "index")
        return "/";
    if (name === "index")
        return "/" + dir;
    return "/" + (dir ? `${dir}/${name}` : name);
}
let loadPromise = null;
export function loadRoutes() {
    if (loadPromise)
        return loadPromise;
    loadPromise = (async () => {
        const files = await walk(routesDir);
        for (const file of files) {
            const base = path.basename(file, path.extname(file));
            const isReserved = base.startsWith("_");
            const isFallback = base === WS_FALLBACK_NAME;
            if (isReserved && !isFallback)
                continue;
            const mod = (await import(pathToFileURL(file).href));
            if (isFallback) {
                if (typeof mod.WS === "function") {
                    defaultWsHandler = mod.WS;
                }
                else {
                    console.error(`[Router] ${WS_FALLBACK_NAME} must export a WS handler. Skipping.`);
                }
                continue;
            }
            const urlPath = fileToUrlPath(file);
            let registered = false;
            for (const method of HTTP_METHODS) {
                const handler = mod[method];
                if (typeof handler === "function") {
                    httpRoutes.push({ method, path: urlPath, handler: handler });
                    registered = true;
                }
            }
            if (typeof mod.WS === "function") {
                wsRoutes.push({ path: urlPath, handler: mod.WS });
                registered = true;
            }
            if (!registered) {
                console.error(`[Router] ${file} exports no recognized method handlers (GET/POST/…/WS). Skipping.`);
            }
        }
        console.error(`[Router] Loaded ${httpRoutes.length} HTTP route(s), ${wsRoutes.length} WS route(s)` +
            (defaultWsHandler ? " + WS fallback" : "") +
            ".");
    })();
    return loadPromise;
}
export async function dispatchHttp(req, res) {
    const url = new URL(req.url || "/", `http://localhost`);
    for (const route of httpRoutes) {
        if (route.path === url.pathname && route.method === req.method) {
            try {
                await route.handler(req, res, url);
            }
            catch (err) {
                console.error(`[Router] Handler error for ${req.method} ${url.pathname}:`, err);
                if (!res.headersSent) {
                    res.writeHead(500);
                    res.end("Internal server error");
                }
            }
            return;
        }
    }
    res.writeHead(200);
    res.end("MCP Server Running");
}
export function dispatchWs(ws, req) {
    const urlPath = req.url || "/";
    const match = wsRoutes.find((r) => r.path === urlPath);
    if (match) {
        match.handler(ws, req);
        return;
    }
    defaultWsHandler?.(ws, req);
}
