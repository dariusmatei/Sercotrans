import { Redis } from 'ioredis';

const REDIS_URL = process.env.REDIS_URL || 'redis://redis:6379';

export const redis = new Redis(REDIS_URL, {
  maxRetriesPerRequest: null,
  enableReadyCheck: true,
});

redis.on('connect', () => console.log('[redis] connected'));
redis.on('error', (err) => console.error('[redis] error', err));
