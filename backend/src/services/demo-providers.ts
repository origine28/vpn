import type { ConnectionConfig, VpnProvider, VpnServerInfo } from './vpn-provider.js';

interface DemoServerRecord {
  id: string;
  name: string;
  countryId: string;
  providerName: string;
}

class DemoProvider implements VpnProvider {
  constructor(
    readonly name: string,
    readonly priority: number,
    private readonly servers: DemoServerRecord[],
  ) {}

  readonly isActive = true;

  getServersForCountry(countryId: string): VpnServerInfo[] {
    return this.servers
      .filter((s) => s.countryId === countryId)
      .map((s) => ({ id: s.id, name: s.name, isActive: true, countryId: s.countryId }));
  }

  isAvailable(): boolean {
    return this.isActive;
  }

  getServerById(serverId: string): VpnServerInfo | null {
    const server = this.servers.find((s) => s.id === serverId);
    if (!server) return null;
    return { id: server.id, name: server.name, isActive: true, countryId: server.countryId };
  }

  getConnectionConfig(server: VpnServerInfo): ConnectionConfig {
    return {
      serverId: server.id,
      serverName: server.name,
      protocol: 'DEMO',
      providerName: this.name,
    };
  }
}

export function createDemoProviderA(servers: DemoServerRecord[]): DemoProvider {
  return new DemoProvider('DemoProviderA', 1, servers);
}

export function createDemoProviderB(servers: DemoServerRecord[]): DemoProvider {
  return new DemoProvider('DemoProviderB', 2, servers);
}
