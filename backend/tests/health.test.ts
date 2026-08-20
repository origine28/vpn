import { describe, expect, it } from 'vitest';

import { buildApp } from '../src/app.js';

describe('GET /health', () => {
  it('retourne 200 avec { status: ok }', async () => {
    const app = await buildApp();
    const response = await app.inject({ method: 'GET', url: '/health' });

    expect(response.statusCode).toBe(200);
    expect(response.headers['content-type']).toContain('application/json');
    expect(response.json()).toEqual({ status: 'ok' });

    await app.close();
  });
});
