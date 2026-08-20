import cors from '@fastify/cors';
import Fastify, { type FastifyInstance } from 'fastify';

import { env } from './config/env.js';
import { countryRoutes } from './routes/countries.js';
import { healthRoutes } from './routes/health.js';
import { serverRoutes } from './routes/servers.js';
import { vpnRoutes } from './routes/vpn.js';

export async function buildApp(): Promise<FastifyInstance> {
  const app = Fastify({
    logger: env.NODE_ENV === 'test' ? false : { level: 'info' },
  });

  const corsOrigin = env.CORS_ORIGIN;
  await app.register(cors, {
    origin: corsOrigin === '*' ? true : corsOrigin.split(','),
  });

  await app.register(healthRoutes);
  await app.register(countryRoutes);
  await app.register(serverRoutes);
  await app.register(vpnRoutes);

  return app;
}
