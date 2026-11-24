import { RobloxResponse } from "../bridge/types.js";
/**
 * Check if the current instance is a secondary relay.
 * Secondaries can be created either via --baseurl or automatically when
 * the port is already in use (EADDRINUSE fallback).
 */
export declare function isSecondaryRelay(): boolean;
/**
 * Relay a tool call to the primary's /api/tool HTTP endpoint.
 * Handles both immediate results and progress-job-based async responses
 * (polls /api/tool-progress until done).
 */
export declare function relayToolToApi(type: string, params: Record<string, unknown>, timeoutMs?: number): Promise<ToolTextResponse>;
export interface ToolTextResponse {
    [x: string]: unknown;
    content: {
        type: "text";
        text: string;
    }[];
    isError?: boolean;
}
export interface SendAndWaitOptions {
    type: string;
    data: Record<string, unknown>;
    timeoutMs?: number;
    failureField?: "output" | "error";
    failureMessage?: (response: RobloxResponse | undefined) => string;
    successMessage?: (response: RobloxResponse) => string;
}
/**
 * Dispatch a request to the Roblox client and wait for the response.
 * Handles the no-client / invalid-client / timeout boilerplate that every
 * tool used to repeat.
 */
export declare function sendAndWait(options: SendAndWaitOptions): Promise<ToolTextResponse>;
export interface FireAndForgetOptions {
    type: string;
    data: Record<string, unknown>;
    successMessage: string;
}
/**
 * Dispatch a request without waiting for a response.
 * Returns a success message once the request has been queued/sent.
 */
export declare function sendFireAndForget(options: FireAndForgetOptions): ToolTextResponse;
