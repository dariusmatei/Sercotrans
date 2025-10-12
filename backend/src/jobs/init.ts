import { projectsWorker } from './workers/projects.worker';
import { projectsQueue } from './queues/projects.queue';

export function initJobs() {
  console.log('[jobs] workers initialized');
  return { projectsWorker, projectsQueue };
}
