import type { IncomingMessage, ServerResponse } from "http";
export declare function GET(req: IncomingMessage, res: ServerResponse, url: URL): void;
export declare function PUT(req: IncomingMessage, res: ServerResponse): Promise<void>;
