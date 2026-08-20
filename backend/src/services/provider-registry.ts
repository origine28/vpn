import type { ConnectionConfig, VpnProvider, VpnServerInfo } from './vpn-provider.js';

export class ProviderRegistry {
  private readonly providers = new Map<string, VpnProvider>();

  register(provider: VpnProvider): void {
    this.providers.set(provider.name, provider);
  }

  get(name: string): VpnProvider | undefined {
    return this.providers.get(name);
  }

  getAllActive(): VpnProvider[] {
    return Array.from(this.providers.values()).filter((p) => p.isActive);
  }

  getServersForCountry(countryId: string): Array<{ provider: VpnProvider; server: VpnServerInfo }> {
    const results: Array<{ provider: VpnProvider; server: VpnServerInfo }> = [];
    for (const provider of this.getAllActive()) {
      const servers = provider.getServersForCountry(countryId);
      for (const server of servers) {
        results.push({ provider, server });
      }
    }
    return results;
  }

  findServerById(serverId: string): { provider: VpnProvider; server: VpnServerInfo } | null {
    for (const provider of this.getAllActive()) {
      const server = provider.getServerById(serverId);
      if (server) {
        return { provider, server };
      }
    }
    return null;
  }

  getConnectionConfig(server: VpnServerInfo, provider: VpnProvider): ConnectionConfig {
    return {
      serverId: server.id,
      serverName: server.name,
      protocol: 'DEMO',
      providerName: provider.name,
    };
  }
}
