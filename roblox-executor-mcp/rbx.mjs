// node rbx.mjs diag/info.lua   -> runs the file in the connected Roblox client and prints what it returns
import fs from "fs";
const file = process.argv[2];
if (!file || !fs.existsSync(file)) {
  console.log("usage: node rbx.mjs <file.lua>");
  process.exit(1);
}
const code = fs.readFileSync(file, "utf8");
let j;
try {
  const r = await fetch("http://127.0.0.1:16384/api/tool", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ type: "get-data-by-code", code, timeout: 90000 }),
  });
  j = await r.json();
} catch (e) {
  console.log("server is not running: start it in the first Termux session (node dist/index.js)");
  process.exit(1);
}
let out = j.result ?? j.error ?? JSON.stringify(j);
// the connector returns the values as a Lua table literal: { "text" }
const m = /^\s*\{\s*"([\s\S]*)"\s*,?\s*\}\s*$/.exec(out);
if (m) out = m[1].replace(/\\n/g, "\n").replace(/\\t/g, "\t").replace(/\\"/g, '"').replace(/\\\\/g, "\\");
console.log(out);
