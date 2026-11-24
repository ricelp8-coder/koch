import type { IncomingMessage, ServerResponse } from "http";
export declare function GET(req: IncomingMessage, res: ServerResponse): Promise<void>;
export declare function POST(req: IncomingMessage, res: ServerResponse): Promise<void>;
