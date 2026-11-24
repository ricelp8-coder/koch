import crypto from "crypto";
import { WebSocket } from "ws";
import { TOOL_RESPONSE_TIMEOUT } from "../../../config.js";
import { getActiveClients, resolveTargetClient } from "./registry.js";
// ─── Instance role ────────────────────────────────────────────────────────────
let instanceRole = "primary";
export function getInstanceRole() {
    return instanceRole;
}
export function setInstanceRole(role) {
    instanceRole = role;
}
// ─── Primary-mode routing state ───────────────────────────────────────────────
export const httpResponseResolvers = new Map();
export const requestToClientId = new Map();
export const relayClients = new Set();
export const relayRequestOrigin = new Map();
// ─── Secondary-mode routing state ─────────────────────────────────────────────
let relaySocket = null;
export const secondaryResponseResolvers = new Map();
export function getRelaySocket() {
    return relaySocket;
}
export function setRelaySocket(ws) {
    relaySocket = ws;
}
export function resetPrimaryState() {
    httpResponseResolvers.clear();
    requestToClientId.clear();
    relayClients.clear();
    relayRequestOrigin.clear();
}
export function resetSecondaryState() {
    secondaryResponseResolvers.clear();
}
// ─── Low-level send ───────────────────────────────────────────────────────────
export function SendToClient(target, message) {
    if (target.transport === "ws" && target.ws && target.ws.readyState === WebSocket.OPEN) {
        target.ws.send(message);
    }
    else if (target.transport === "http") {
        target.pendingHttpCommand = message;
    }
}
// ─── Response waiter ──────────────────────────────────────────────────────────
export function GetResponseOfIdFromClient(id, timeoutMs = TOOL_RESPONSE_TIMEOUT) {
    return new Promise((resolve) => {
        let settled = false;
        let timeout;
        const resolveOnce = (data) => {
            if (settled)
                return;
            settled = true;
            clearTimeout(timeout);
            resolve(data);
        };
        timeout = setTimeout(() => {
            if (instanceRole === "secondary") {
                secondaryResponseResolvers.delete(id);
            }
            else {
                httpResponseResolvers.delete(id);
            }
            resolveOnce({
                id,
                output: undefined,
                error: `Timed out waiting for response after ${timeoutMs}ms.`,
            });
        }, timeoutMs);
        if (instanceRole === "secondary") {
            secondaryResponseResolvers.set(id, resolveOnce);
            return;
        }
        httpResponseResolvers.set(id, resolveOnce);
    });
}
// ─── High-level dispatch ──────────────────────────────────────────────────────
export function SendArbitraryDataToClient(type, data, id, clientId) {
    if (instanceRole === "secondary") {
        if (!relaySocket || relaySocket.readyState !== WebSocket.OPEN)
            return null;
        const requestId = id ?? crypto.randomUUID();
        const message = {
            id: requestId,
            ...data,
            type,
            ...(clientId ? { targetClientId: clientId } : {}),
        };
        relaySocket.send(JSON.stringify(message));
        return requestId;
    }
    // Primary mode
    if (clientId !== undefined) {
        const target = resolveTargetClient(clientId);
        if (!target)
            return "INVALID_CLIENT";
        const requestId = id ?? crypto.randomUUID();
        const message = { id: requestId, ...data, type };
        requestToClientId.set(requestId, target.clientId);
        SendToClient(target, JSON.stringify(message));
        return requestId;
    }
    // No clientId: broadcast to all active clients (most recent wins for routing)
    const activeClients = getActiveClients();
    if (activeClients.length === 0)
        return null;
    const requestId = id ?? crypto.randomUUID();
    const message = { id: requestId, ...data, type };
    for (const target of activeClients) {
        requestToClientId.set(requestId, target.clientId);
        SendToClient(target, JSON.stringify(message));
    }
    return requestId;
}
// ─── Route a response from a Roblox client ────────────────────────────────────
export function handleRobloxResponse(data) {
    if (!data.id)
        return;
    // If the request originated from a relayed secondary, forward it back.
    const originRelay = relayRequestOrigin.get(data.id);
    if (originRelay && originRelay.readyState === WebSocket.OPEN) {
        originRelay.send(JSON.stringify(data));
        relayRequestOrigin.delete(data.id);
        requestToClientId.delete(data.id);
        return;
    }
    relayRequestOrigin.delete(data.id);
    // Otherwise it's a local primary request.
    const resolver = httpResponseResolvers.get(data.id);
    if (resolver) {
        resolver(data);
        httpResponseResolvers.delete(data.id);
    }
    requestToClientId.delete(data.id);
}
