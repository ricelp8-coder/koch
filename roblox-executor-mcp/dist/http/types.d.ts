import type { IncomingMessage, ServerResponse } from "http";
import type { WebSocket } from "ws";
export type HttpMethod = "GET" | "POST" | "PUT" | "DELETE" | "PATCH" | "OPTIONS";
export declare const HTTP_METHODS: HttpMethod[];
export type RouteHandler = (req: IncomingMessage, res: ServerResponse, url: URL) => void | Promise<void>;
export type WsRouteHandler = (ws: WebSocket, req: IncomingMessage) => void;
