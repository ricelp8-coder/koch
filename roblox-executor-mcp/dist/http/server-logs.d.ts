/**
 * Server log buffer — intercepts console.error (stderr) and stores recent entries
 * for the dashboard to display.
 */
export interface ServerLogEntry {
    timestamp: string;
    level: "error" | "warn" | "info";
    message: string;
}
/** Get all buffered server logs (newest first). */
export declare function getServerLogs(limit?: number): ServerLogEntry[];
/** Clear the server log buffer. */
export declare function clearServerLogs(): void;
/** Monkey-patch console.error/warn to also buffer logs. Call once at startup. */
export declare function installServerLogCapture(): void;
