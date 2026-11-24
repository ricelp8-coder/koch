import crypto from "node:crypto";
const jobs = new Map();
const JOB_TTL_MS = 15 * 60 * 1000;
function pruneJobs() {
    const cutoff = Date.now() - JOB_TTL_MS;
    for (const [id, job] of jobs) {
        if (job.updatedAt < cutoff)
            jobs.delete(id);
    }
}
export function createProgressJob(type, message) {
    pruneJobs();
    const now = Date.now();
    const job = {
        id: crypto.randomUUID(),
        type,
        status: "running",
        message,
        completed: 0,
        total: 0,
        startedAt: now,
        updatedAt: now,
    };
    jobs.set(job.id, job);
    return job;
}
export function updateProgressJob(id, patch) {
    const job = jobs.get(id);
    if (!job || job.status !== "running")
        return;
    Object.assign(job, patch, { updatedAt: Date.now() });
}
export function completeProgressJob(id, result) {
    const job = jobs.get(id);
    if (!job)
        return;
    job.status = "done";
    job.result = result;
    job.message = "Completed";
    job.completed = job.total || job.completed;
    job.updatedAt = Date.now();
}
export function failProgressJob(id, error) {
    const job = jobs.get(id);
    if (!job)
        return;
    job.status = "error";
    job.error = error;
    job.message = error;
    job.updatedAt = Date.now();
}
export function getProgressJob(id) {
    pruneJobs();
    return jobs.get(id);
}
