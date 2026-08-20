import type { ConnectionConfig, VpnServerInfo } from './vpn-provider.js';
import type { ProviderRegistry } from './provider-registry.js';

export interface OrchestratorResult {
  server: VpnServerInfo;
  providerName: string;
  config: ConnectionConfig;
}

export class VpnOrchestratorService {
  constructor(private readonly registry: ProviderRegistry) {}

  selectServer(countryId: string): OrchestratorResult | null {
    const candidates = this.registry.getServersForCountry(countryId);

    if (candidates.length === 0) {
      return null;
    }

    const sorted = candidates.sort((a, b) => {
      if (a.provider.priority !== b.provider.priority) {
        return a.provider.priority - b.provider.priority;
      }
      return a.server.name.localeCompare(b.server.name);
    });

    const best = sorted[0];
    const config = this.registry.getConnectionConfig(best.server, best.provider);

    return {
      server: best.server,
      providerName: best.provider.name,
      config,
    };
  }
}
