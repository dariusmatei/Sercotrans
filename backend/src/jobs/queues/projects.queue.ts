import { Queue } from 'bullmq';
import { redis } from '../redis';

export const projectsQueue = new Queue('projects', { connection: redis });

export async function enqueueProjectSync(projectId: string) {
  await projectsQueue.add('sync', { projectId }, { attempts: 3, backoff: { type: 'exponential', delay: 1000 } });
}
