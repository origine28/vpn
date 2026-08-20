import type { FastifyInstance } from 'fastify';

import { countries } from '../data/countries.js';

export async function countryRoutes(app: FastifyInstance): Promise<void> {
  app.get('/countries', async () => {
    return countries;
  });
}
