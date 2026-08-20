import { describe, expect, it } from 'vitest';

import { ProviderRegistry } from '../src/services/provider-registry.js';
import { createDemoProviderA, createDemoProviderB } from '../src/services/demo-providers.js';

function createTestRegistry(): ProviderRegistry {
  const registry = new ProviderRegistry();

  const providerA = createDemoProviderA([
    { id: 'fr-01', name: 'demo-fr-01', countryId: 'country-fr', providerName: 'DemoProviderA' },
    { id: 'de-01', name: 'demo-de-01', countryId: 'country-de', providerName: 'DemoProviderA' },
    { id: 'us-01', name: 'demo-us-01', countryId: 'country-us', providerName: 'DemoProviderA' },
  ]);

  const providerB = createDemoProviderB([
    { id: 'fr-02', name: 'demo-fr-02', countryId: 'country-fr', providerName: 'DemoProviderB' },
    { id: 'de-02', name: 'demo-de-02', countryId: 'country-de', providerName: 'DemoProviderB' },
  ]);

  registry.register(providerA);
  registry.register(providerB);

  return registry;
}

describe('ProviderRegistry', () => {
  it('enregistre et récupère un provider', () => {
    const registry = createTestRegistry();
    const provider = registry.get('DemoProviderA');
    expect(provider).toBeDefined();
    expect(provider!.name).toBe('DemoProviderA');
  });

  it('retourne tous les providers actifs', () => {
    const registry = createTestRegistry();
    const active = registry.getAllActive();
    expect(active).toHaveLength(2);
  });

  it('retourne les serveurs pour un pays donné', () => {
    const registry = createTestRegistry();
    const servers = registry.getServersForCountry('country-fr');
    expect(servers).toHaveLength(2);
    expect(servers.map((s) => s.server.name)).toContain('demo-fr-01');
    expect(servers.map((s) => s.server.name)).toContain('demo-fr-02');
  });

  it('retourne vide pour un pays inexistant', () => {
    const registry = createTestRegistry();
    const servers = registry.getServersForCountry('country-xx');
    expect(servers).toHaveLength(0);
  });

  it('trouve un serveur par ID', () => {
    const registry = createTestRegistry();
    const result = registry.findServerById('fr-01');
    expect(result).not.toBeNull();
    expect(result!.server.name).toBe('demo-fr-01');
    expect(result!.provider.name).toBe('DemoProviderA');
  });

  it('retourne null pour un serveur inexistant', () => {
    const registry = createTestRegistry();
    const result = registry.findServerById('nonexistent');
    expect(result).toBeNull();
  });

  it('génère une config de connexion', () => {
    const registry = createTestRegistry();
    const result = registry.findServerById('fr-01')!;
    const config = registry.getConnectionConfig(result.server, result.provider);
    expect(config.serverId).toBe('fr-01');
    expect(config.serverName).toBe('demo-fr-01');
    expect(config.protocol).toBe('DEMO');
    expect(config.providerName).toBe('DemoProviderA');
  });
});
