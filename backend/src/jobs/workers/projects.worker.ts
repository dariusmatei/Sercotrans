import { Worker, Job } from 'bullmq';
import { redis } from '../redis';

export const projectsWorker = new Worker('projects', async (job: Job) => {
  switch (job.name) {
    case 'sync':
      console.log('[worker] syncing project', job.data.projectId);
      break;
    default:
      console.log('[worker] unknown job', job.name);
  }
}, { connection: redis });

projectsWorker.on('completed', (job) => console.log('[worker] completed', job.id));
projectsWorker.on('failed', (job, err) => console.error('[worker] failed', job?.id, err));
