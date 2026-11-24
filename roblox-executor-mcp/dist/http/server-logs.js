/**
 * Server log buffer — intercepts console.error (stderr) and stores recent entries
 * for the dashboard to display.
 */
const MAX_LOGS = 500;
const logBuffer = [];
/** Get all buffered server logs (newest first). */
export function getServerLogs(limit = 100) {
    return logBuffer.slice(0, Math.min(limit, logBuffer.length));
}
/** Clear the server log buffer. */
export function clearServerLogs() {
    logBuffer.length = 0;
}
function classifyLevel(args) {
    const msg = args
        .map((a) => (typeof a === "string" ? a : ""))
        .join(" ")
        .toLowerCase();
    if (msg.includes("error") ||
        msg.includes("fatal") ||
        msg.includes("failed"))
        return "error";
    if (msg.includes("warn"))
        return "warn";
    return "info";
}
function pushLog(level, args) {
    const message = args
        .map((a) => (typeof a === "string" ? a : JSON.stringify(a)))
        .join(" ");
    logBuffer.unshift({
        timestamp: new Date().toISOString(),
        level,
        message,
    });
    if (logBuffer.length > MAX_LOGS)
        logBuffer.length = MAX_LOGS;
}
/** Monkey-patch console.error/warn to also buffer logs. Call once at startup. */
export function installServerLogCapture() {
    const origError = console.error.bind(console);
    const origWarn = console.warn.bind(console);
    console.error = (...args) => {
        origError(...args);
        pushLog(classifyLevel(args), args);
    };
    console.warn = (...args) => {
        origWarn(...args);
        pushLog("warn", args);
    };
}
