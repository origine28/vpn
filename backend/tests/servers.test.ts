import { describe, expect, it } from 'vitest';

import { buildApp } from '../src/app.js';

describe('GET /countries/:countryCode/servers', () => {
  it('retourne les serveurs pour la France', async () => {
    const app = await buildApp();
    const response = await app.inject({
      method: 'GET',
      url: '/countries/FR/servers',
    });

    expect(response.statusCode).toBe(200);

    const body = response.json();
    expect(body.country.code).toBe('FR');
    expect(body.country.name).toBe('France');
    expect(body.country.flag).toBe('🇫🇷');
    expect(body.servers.length).toBeGreaterThanOrEqual(1);

    for (const server of body.servers) {
      expect(server.id).toBeTypeOf('string');
      expect(server.name).toBeTypeOf('string');
      expect(server.name).toMatch(/^demo-fr-/);
      expect(server.provider).toBeTypeOf('string');
    }

    await app.close();
  });

  it('retourne 404 pour un pays inexistant', async () => {
    const app = await buildApp();
    const response = await app.inject({
      method: 'GET',
      url: '/countries/XX/servers',
    });

    expect(response.statusCode).toBe(404);
    expect(response.json().error).toBe('Country not found');

    await app.close();
  });

  it('accepte le code pays en minuscules', async () => {
    const app = await buildApp();
    const response = await app.inject({
      method: 'GET',
      url: '/countries/de/servers',
    });

    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(body.country.code).toBe('DE');
    expect(body.servers.length).toBeGreaterThanOrEqual(1);

    await app.close();
  });
});
