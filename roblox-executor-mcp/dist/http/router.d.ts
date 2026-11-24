import type { IncomingMessage, ServerResponse } from "http";
import type { WebSocket } from "ws";
export declare function loadRoutes(): Promise<void>;
export declare function dispatchHttp(req: IncomingMessage, res: ServerResponse): Promise<void>;
export declare function dispatchWs(ws: WebSocket, req: IncomingMessage): void;
