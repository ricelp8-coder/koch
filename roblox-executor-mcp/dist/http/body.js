export function readBody(req) {
    return new Promise((resolve, reject) => {
        let body = "";
        req.on("data", (chunk) => {
            body += chunk.toString();
        });
        req.on("end", () => resolve(body));
        req.on("error", reject);
    });
}
export async function readJsonBody(req) {
    const raw = await readBody(req);
    return raw ? JSON.parse(raw) : {};
}
