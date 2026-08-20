export interface VpnServerInfo {
  id: string;
  name: string;
  isActive: boolean;
  countryId: string;
}

export interface VpnProvider {
  readonly name: string;
  readonly priority: number;
  readonly isActive: boolean;

  getServersForCountry(countryId: string): VpnServerInfo[];

  isAvailable(): boolean;

  getServerById(serverId: string): VpnServerInfo | null;
}

export interface ConnectionConfig {
  serverId: string;
  serverName: string;
  protocol: string;
  providerName: string;
}
