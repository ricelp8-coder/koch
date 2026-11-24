export type ProgressStatus = "running" | "done" | "error";
export interface ProgressJob {
    id: string;
    type: string;
    status: ProgressStatus;
    message: string;
    completed: number;
    total: number;
    result?: string;
    error?: string;
    startedAt: number;
    updatedAt: number;
}
export declare function createProgressJob(type: string, message: string): ProgressJob;
export declare function updateProgressJob(id: string, patch: Partial<Pick<ProgressJob, "message" | "completed" | "total">>): void;
export declare function completeProgressJob(id: string, result: string): void;
export declare function failProgressJob(id: string, error: string): void;
export declare function getProgressJob(id: string): ProgressJob | undefined;
