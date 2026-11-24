import { GetResponseOfIdFromClient, SendArbitraryDataToClient, getInstanceRole, } from "../bridge/handlers/shared/communication.js";
import { getActiveClientId } from "../bridge/handlers/shared/registry.js";
import { BASE_URL, WS_PORT } from "../config.js";
import { INVALID_CLIENT_ERROR, NO_CLIENT_ERROR } from "./errors.js";
/**
 * Check if the current instance is a secondary relay.
 * Secondaries can be created either via --baseurl or automatically when
 * the port is already in use (EADDRINUSE fallback).
 */
export function isSecondaryRelay() {
    return getInstanceRole() === "secondary";
}
/**
 * Get the base URL of the primary server.
 * If --baseurl was specified, use that. Otherwise fall back to localhost.
 */
function getPrimaryBaseUrl() {
    if (BASE_URL)
        return BASE_URL.replace(/\/$/, "");
    return `http://localhost:${WS_PORT}`;
}
/**
 * Relay a tool call to the primary's /api/tool HTTP endpoint.
 * Handles both immediate results and progress-job-based async responses
 * (polls /api/tool-progress until done).
 */
export async function relayToolToApi(type, params, timeoutMs = 60000) {
    const primaryBase = getPrimaryBaseUrl();
    const toolUrl = primaryBase + "/api/tool";
    const activeClientId = getActiveClientId();
    try {
        const resp = await fetch(toolUrl, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                type,
                ...(activeClientId ? { clientId: activeClientId } : {}),
                ...params,
            }),
        });
        const data = (await resp.json());
        if (data.error) {
            return { content: [{ type: "text", text: data.error }], isError: true };
        }
        // Immediate result
        if (data.result !== undefined) {
            return { content: [{ type: "text", text: data.result }] };
        }
        // Progress-job based (semantic search/index)
        if (data.jobId && data.progressUrl) {
            const progressUrl = primaryBase + data.progressUrl;
            const deadline = Date.now() + timeoutMs;
            while (Date.now() < deadline) {
                await new Promise((r) => setTimeout(r, 1000));
                const progressResp = await fetch(progressUrl);
                const job = (await progressResp.json());
                if (job.status === "done") {
                    return { content: [{ type: "text", text: job.result ?? "Done." }] };
                }
                if (job.status === "failed") {
                    return {
                        content: [{ type: "text", text: `Failed: ${job.error ?? "Unknown error"}` }],
                        isError: true,
                    };
                }
            }
            return { content: [{ type: "text", text: "Timed out waiting for primary to complete." }], isError: true };
        }
        return { content: [{ type: "text", text: JSON.stringify(data) }] };
    }
    catch (err) {
        return {
            content: [{ type: "text", text: `Failed to relay to primary: ${err.message || err}` }],
            isError: true,
        };
    }
}
/**
 * Dispatch a request to the Roblox client and wait for the response.
 * Handles the no-client / invalid-client / timeout boilerplate that every
 * tool used to repeat.
 */
export async function sendAndWait(options) {
    const callId = SendArbitraryDataToClient(options.type, options.data, undefined, getActiveClientId());
    if (callId === null)
        return NO_CLIENT_ERROR;
    if (callId === "INVALID_CLIENT")
        return INVALID_CLIENT_ERROR;
    const response = await GetResponseOfIdFromClient(callId, options.timeoutMs);
    const failureField = options.failureField ?? "output";
    const isFailure = response === undefined ||
        (failureField === "error"
            ? response.error !== undefined
            : response.output === undefined);
    if (isFailure) {
        const text = options.failureMessage?.(response) ??
            `Failed to ${options.type}. Response: ${JSON.stringify(response)}`;
        return { content: [{ type: "text", text }] };
    }
    const text = options.successMessage?.(response) ?? response.output;
    return { content: [{ type: "text", text }] };
}
/**
 * Dispatch a request without waiting for a response.
 * Returns a success message once the request has been queued/sent.
 */
export function sendFireAndForget(options) {
    const callId = SendArbitraryDataToClient(options.type, options.data, undefined, getActiveClientId());
    if (callId === null)
        return NO_CLIENT_ERROR;
    if (callId === "INVALID_CLIENT")
        return INVALID_CLIENT_ERROR;
    return { content: [{ type: "text", text: options.successMessage }] };
}
