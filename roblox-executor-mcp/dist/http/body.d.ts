import type { IncomingMessage } from "http";
export declare function readBody(req: IncomingMessage): Promise<string>;
export declare function readJsonBody<T>(req: IncomingMessage): Promise<T>;
