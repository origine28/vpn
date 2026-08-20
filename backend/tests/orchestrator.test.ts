import { describe, expect, it } from 'vitest';

import { ProviderRegistry } from '../src/services/provider-registry.js';
import { VpnOrchestratorService } from '../src/services/vpn-orchestrator.js';
import { createDemoProviderA, createDemoProviderB } from '../src/services/demo-providers.js';

function createTestOrchestrator(): VpnOrchestratorService {
  const registry = new ProviderRegistry();

  const providerA = createDemoProviderA([
    { id: 'fr-01', name: 'demo-fr-01', countryId: 'country-fr', providerName: 'DemoProviderA' },
    { id: 'de-01', name: 'demo-de-01', countryId: 'country-de', providerName: 'DemoProviderA' },
  ]);

  const providerB = createDemoProviderB([
    { id: 'fr-02', name: 'demo-fr-02', countryId: 'country-fr', providerName: 'DemoProviderB' },
    { id: 'de-02', name: 'demo-de-02', countryId: 'country-de', providerName: 'DemoProviderB' },
  ]);

  registry.register(providerA);
  registry.register(providerB);

  return new VpnOrchestratorService(registry);
}

describe('VpnOrchestratorService', () => {
  it('sélectionne le serveur avec la priorité la plus basse', () => {
    const orchestrator = createTestOrchestrator();
    const result = orchestrator.selectServer('country-fr');
    expect(result).not.toBeNull();
    expect(result!.server.name).toBe('demo-fr-01');
    expect(result!.providerName).toBe('DemoProviderA');
    expect(result!.config.protocol).toBe('DEMO');
  });

  it('retourne null pour un pays sans serveurs', () => {
    const orchestrator = createTestOrchestrator();
    const result = orchestrator.selectServer('country-xx');
    expect(result).toBeNull();
  });

  it('est déterministe : même pays = même résultat', () => {
    const orchestrator = createTestOrchestrator();
    const result1 = orchestrator.selectServer('country-de');
    const result2 = orchestrator.selectServer('country-de');
    expect(result1!.server.name).toBe(result2!.server.name);
    expect(result1!.providerName).toBe(result2!.providerName);
  });

  it('retourne un config sans secrets ni clés', () => {
    const orchestrator = createTestOrchestrator();
    const result = orchestrator.selectServer('country-fr');
    expect(result).not.toBeNull();
    const config = result!.config;
    expect(config).not.toHaveProperty('privateKey');
    expect(config).not.toHaveProperty('secret');
    expect(config).not.toHaveProperty('apiKey');
    expect(config).not.toHaveProperty('credential');
    expect(config).toHaveProperty('serverId');
    expect(config).toHaveProperty('serverName');
    expect(config).toHaveProperty('protocol');
    expect(config).toHaveProperty('providerName');
  });
});
