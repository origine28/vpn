import { describe, expect, it } from 'vitest';

import { buildApp } from '../src/app.js';

describe('GET /countries', () => {
  it('retourne 200 avec la liste des pays', async () => {
    const app = await buildApp();
    const response = await app.inject({ method: 'GET', url: '/countries' });

    expect(response.statusCode).toBe(200);
    expect(response.headers['content-type']).toContain('application/json');

    const body = response.json();
    expect(Array.isArray(body)).toBe(true);
    expect(body.length).toBeGreaterThanOrEqual(6);
    expect(body[0]).toEqual({ code: 'FR', name: 'France', flag: '🇫🇷' });

    await app.close();
  });

  it('chaque pays expose code, name et flag (strings non vides)', async () => {
    const app = await buildApp();
    const response = await app.inject({ method: 'GET', url: '/countries' });
    const body = response.json();

    for (const country of body) {
      expect(country.code).toBeTypeOf('string');
      expect(country.code.length).toBeGreaterThan(0);
      expect(country.name).toBeTypeOf('string');
      expect(country.name.length).toBeGreaterThan(0);
      expect(country.flag).toBeTypeOf('string');
      expect(country.flag.length).toBeGreaterThan(0);
    }

    await app.close();
  });

  it('les codes de pays sont uniques', async () => {
    const app = await buildApp();
    const response = await app.inject({ method: 'GET', url: '/countries' });
    const codes = response.json().map((country: { code: string }) => country.code);

    expect(new Set(codes).size).toBe(codes.length);

    await app.close();
  });
});
