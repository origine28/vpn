import { describe, expect, it } from 'vitest';

import { buildApp } from '../src/app.js';

// Dummy WireGuard public key for tests (valid base64, 32 bytes)
const TEST_CLIENT_PUBLIC_KEY = 'TestClientPublicKey123456789012345678=';
const TEST_PUBLIC_KEY_2 = 'AnotherClientPublicKey12345678901234=';

describe('POST /vpn/connect', () => {
  it('connecte au pays demandé et retourne les informations', async () => {
    const app = await buildApp();
    const response = await app.inject({
      method: 'POST',
      url: '/vpn/connect',
      payload: { countryCode: 'FR', clientPublicKey: TEST_CLIENT_PUBLIC_KEY },
    });

    expect(response.statusCode).toBe(200);

    const body = response.json();
    expect(body.connectionId).toBeTypeOf('string');
    expect(body.country).toBe('FR');
    expect(body.server.id).toBeTypeOf('string');
    expect(body.server.name).toMatch(/^demo-fr-/);
    expect(body.protocol).toBe('DEMO');
    expect(body.status).toBe('READY');
    expect(body.expiresAt).toBeTypeOf('string');

    await app.close();
  });

  it('retourne 400 si countryCode manque', async () => {
    const app = await buildApp();
    const response = await app.inject({
      method: 'POST',
      url: '/vpn/connect',
      payload: { clientPublicKey: TEST_CLIENT_PUBLIC_KEY },
    });

    expect(response.statusCode).toBe(400);
    expect(response.json().message).toContain('countryCode est requis');

    await app.close();
  });

  it('retourne 400 si clientPublicKey manque', async () => {
    const app = await buildApp();
    const response = await app.inject({
      method: 'POST',
      url: '/vpn/connect',
      payload: { countryCode: 'FR' },
    });

    expect(response.statusCode).toBe(400);
    expect(response.json().message).toContain('clientPublicKey est requis');

    await app.close();
  });

  it('retourne 404 pour un pays inexistant', async () => {
    const app = await buildApp();
    const response = await app.inject({
      method: 'POST',
      url: '/vpn/connect',
      payload: { countryCode: 'XX', clientPublicKey: TEST_CLIENT_PUBLIC_KEY },
    });

    expect(response.statusCode).toBe(404);
    expect(response.json().error).toBe('Country not found');

    await app.close();
  });

  it('ne retourne aucun secret ni clé privée', async () => {
    const app = await buildApp();
    const response = await app.inject({
      method: 'POST',
      url: '/vpn/connect',
      payload: { countryCode: 'US', clientPublicKey: TEST_CLIENT_PUBLIC_KEY },
    });

    const body = response.json();
    expect(body).not.toHaveProperty('privateKey');
    expect(body).not.toHaveProperty('secret');
    expect(body).not.toHaveProperty('apiKey');
    expect(body).not.toHaveProperty('credential');
    expect(body).not.toHaveProperty('wireguardConfig');

    await app.close();
  });

  it('retourne la configuration wireguard', async () => {
    const app = await buildApp();
    const response = await app.inject({
      method: 'POST',
      url: '/vpn/connect',
      payload: { countryCode: 'FR', clientPublicKey: TEST_CLIENT_PUBLIC_KEY },
    });

    const body = response.json();
    expect(body.wireguard).toBeDefined();
    expect(body.wireguard.serverPublicKey).toBeTypeOf('string');
    expect(body.wireguard.serverPublicKey.length).toBeGreaterThan(0);
    expect(body.wireguard.serverEndpoint).toContain(':');
    expect(body.wireguard.allowedIPs).toBeInstanceOf(Array);
    expect(body.wireguard.dnsServer).toBeTypeOf('string');
    expect(body.wireguard.mtu).toBe(1420);
    expect(body.wireguard.clientAddress).toBeTypeOf('string');

    await app.close();
  });

  it('retourne le mode d\'opération (SIMULATION ou LIVE)', async () => {
    const app = await buildApp();
    const response = await app.inject({
      method: 'POST',
      url: '/vpn/connect',
      payload: { countryCode: 'FR', clientPublicKey: TEST_CLIENT_PUBLIC_KEY },
    });

    const body = response.json();
    expect(body.mode).toBeDefined();
    expect(['SIMULATION', 'LIVE']).toContain(body.mode);

    await app.close();
  });

  it('stocke la clientPublicKey fournie', async () => {
    const app = await buildApp();
    const response = await app.inject({
      method: 'POST',
      url: '/vpn/connect',
      payload: { countryCode: 'FR', clientPublicKey: TEST_PUBLIC_KEY_2 },
    });

    expect(response.statusCode).toBe(200);

    await app.close();
  });
});

describe('POST /vpn/disconnect', () => {
  it('déconnecte une connexion existante', async () => {
    const app = await buildApp();

    const connectResponse = await app.inject({
      method: 'POST',
      url: '/vpn/connect',
      payload: { countryCode: 'DE', clientPublicKey: TEST_CLIENT_PUBLIC_KEY },
    });
    const { connectionId } = connectResponse.json();

    const disconnectResponse = await app.inject({
      method: 'POST',
      url: '/vpn/disconnect',
      payload: { connectionId },
    });

    expect(disconnectResponse.statusCode).toBe(200);
    expect(disconnectResponse.json().status).toBe('DISCONNECTED');

    await app.close();
  });

  it('retourne 400 si connectionId manque', async () => {
    const app = await buildApp();
    const response = await app.inject({
      method: 'POST',
      url: '/vpn/disconnect',
      payload: {},
    });

    expect(response.statusCode).toBe(400);
    expect(response.json().message).toContain('connectionId est requis');

    await app.close();
  });

  it('retourne 404 pour une connexion inexistante', async () => {
    const app = await buildApp();
    const response = await app.inject({
      method: 'POST',
      url: '/vpn/disconnect',
      payload: { connectionId: 'nonexistent-id' },
    });

    expect(response.statusCode).toBe(404);

    await app.close();
  });

  it('retourne 404 si déjà déconnecté', async () => {
    const app = await buildApp();

    const connectResponse = await app.inject({
      method: 'POST',
      url: '/vpn/connect',
      payload: { countryCode: 'NL', clientPublicKey: TEST_CLIENT_PUBLIC_KEY },
    });
    const { connectionId } = connectResponse.json();

    await app.inject({
      method: 'POST',
      url: '/vpn/disconnect',
      payload: { connectionId },
    });

    const secondDisconnect = await app.inject({
      method: 'POST',
      url: '/vpn/disconnect',
      payload: { connectionId },
    });

    expect(secondDisconnect.statusCode).toBe(404);

    await app.close();
  });
});
