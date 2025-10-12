import type { Express } from 'express';
import projectsRouter from './projects.router';

export function registerRoutes(app: Express) {
  app.use(projectsRouter);
}
