import type { IncomingMessage, ServerResponse } from "http";
export declare function GET(_req: IncomingMessage, res: ServerResponse): Promise<void>;
export declare function PUT(req: IncomingMessage, res: ServerResponse): Promise<void>;
export declare function DELETE(_req: IncomingMessage, res: ServerResponse): Promise<void>;
