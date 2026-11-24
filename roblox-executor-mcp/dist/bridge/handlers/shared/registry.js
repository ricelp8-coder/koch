import crypto from "crypto";
import { WebSocket } from "ws";
import { HTTP_POLL_TIMEOUT } from "../../../config.js";
import { clearScriptSourceIndex } from "./script-source-store.js";
const clientRegistry = new Map();
const wsToClientId = new Map();
let activeClientId = undefined;
export function getActiveClientId() {
    return activeClientId;
}
export function setActiveClientId(clientId) {
    activeClientId = clientId;
}
export function resetRegistry() {
    clientRegistry.clear();
    wsToClientId.clear();
}
export function registerClient(info) {
    const clientId = crypto.randomUUID();
    const entry = {
        clientId,
        username: info.username,
        userId: info.userId,
        placeId: info.placeId,
        jobId: info.jobId,
        placeName: info.placeName,
        transport: info.transport,
        ws: info.ws,
        lastHttpPoll: Date.now(),
        pendingHttpCommand: null,
    };
    clientRegistry.set(clientId, entry);
    if (info.ws) {
        wsToClientId.set(info.ws, clientId);
    }
    console.error(`[Registry] Client registered: ${clientId} (${info.username} @ ${info.placeName}, ${info.transport})`);
    return clientId;
}
export function unregisterClient(clientId) {
    const entry = clientRegistry.get(clientId);
    if (entry?.ws) {
        wsToClientId.delete(entry.ws);
    }
    clientRegistry.delete(clientId);
    clearScriptSourceIndex(clientId);
    console.error(`[Registry] Client unregistered: ${clientId}`);
}
export function getClientById(clientId) {
    return clientRegistry.get(clientId);
}
export function getClientIdByWs(ws) {
    return wsToClientId.get(ws);
}
export function getActiveClients() {
    const active = [];
    for (const entry of clientRegistry.values()) {
        if (entry.transport === "ws") {
            if (entry.ws && entry.ws.readyState === WebSocket.OPEN) {
                active.push(entry);
            }
        }
        else if (Date.now() - entry.lastHttpPoll < HTTP_POLL_TIMEOUT) {
            active.push(entry);
        }
    }
    return active;
}
export function formatActiveClientListForTool() {
    const active = getActiveClients();
    if (active.length === 0) {
        return "No Roblox clients are currently connected.";
    }
    const clientList = active.map((c) => ({
        clientId: c.clientId,
        username: c.username,
        placeId: c.placeId,
        jobId: c.jobId,
        placeName: c.placeName,
        transport: c.transport,
    }));
    return JSON.stringify(clientList, null, 2);
}
export function resolveTargetClient(clientId) {
    if (clientId) {
        const entry = clientRegistry.get(clientId);
        if (!entry)
            return null;
        if (entry.transport === "ws" && (!entry.ws || entry.ws.readyState !== WebSocket.OPEN)) {
            return null;
        }
        if (entry.transport === "http" && Date.now() - entry.lastHttpPoll >= HTTP_POLL_TIMEOUT) {
            return null;
        }
        return entry;
    }
    const active = getActiveClients();
    if (active.length === 0)
        return null;
    const wsCl = active.filter((c) => c.transport === "ws");
    if (wsCl.length > 0)
        return wsCl[wsCl.length - 1];
    return active.sort((a, b) => b.lastHttpPoll - a.lastHttpPoll)[0];
}
