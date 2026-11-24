import type { IncomingMessage, ServerResponse } from "http";
export declare function GET(req: IncomingMessage, res: ServerResponse, url: URL): Promise<void>;
