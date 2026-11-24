export interface RobloxWindowInfo {
    pid: number;
    hwnd: string;
    title: string;
}
export interface ScreenshotResult {
    error?: string;
    needsDisambiguation?: boolean;
    windows?: RobloxWindowInfo[];
    imageBase64?: string;
}
export declare function isSupported(): boolean;
export declare function enumRobloxWindows(): RobloxWindowInfo[];
export declare function performScreenshot(pid?: number): ScreenshotResult;
