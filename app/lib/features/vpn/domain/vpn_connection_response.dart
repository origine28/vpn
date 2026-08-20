class VpnConnectionResponse {
  const VpnConnectionResponse({
    required this.connectionId,
    required this.country,
    required this.server,
    required this.protocol,
    required this.status,
    required this.expiresAt,
    this.wireguard,
    this.mode,
  });

  factory VpnConnectionResponse.fromJson(Map<String, dynamic> json) =>
      VpnConnectionResponse(
        connectionId: json['connectionId'] as String,
        country: json['country'] as String,
        server: ConnectionServer.fromJson(
            json['server'] as Map<String, dynamic>),
        protocol: json['protocol'] as String,
        status: json['status'] as String,
        expiresAt: json['expiresAt'] as String,
        wireguard: json['wireguard'] != null
            ? WireGuardServerConfig.fromJson(
                json['wireguard'] as Map<String, dynamic>)
            : null,
        mode: json['mode'] as String?,
      );

  final String connectionId;
  final String country;
  final ConnectionServer server;
  final String protocol;
  final String status;
  final String expiresAt;

  /// Configuration WireGuard du serveur (Phase 4).
  final WireGuardServerConfig? wireguard;

  /// Mode d'opération : SIMULATION ou LIVE.
  final String? mode;
}

class ConnectionServer {
  const ConnectionServer({
    required this.id,
    required this.name,
  });

  factory ConnectionServer.fromJson(Map<String, dynamic> json) =>
      ConnectionServer(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  final String id;
  final String name;
}

/// Configuration WireGuard du serveur retournée par le backend.
class WireGuardServerConfig {
  const WireGuardServerConfig({
    required this.serverPublicKey,
    required this.serverEndpoint,
    this.allowedIPs,
    this.dnsServer,
    this.clientAddress,
    this.mtu,
  });

  factory WireGuardServerConfig.fromJson(Map<String, dynamic> json) =>
      WireGuardServerConfig(
        serverPublicKey: json['serverPublicKey'] as String,
        serverEndpoint: json['serverEndpoint'] as String,
        allowedIPs: (json['allowedIPs'] as List?)
            ?.map((e) => e as String)
            .toList(),
        dnsServer: json['dnsServer'] as String?,
        clientAddress: json['clientAddress'] as String?,
        mtu: json['mtu'] as int?,
      );

  final String serverPublicKey;
  final String serverEndpoint;
  final List<String>? allowedIPs;
  final String? dnsServer;
  final String? clientAddress;
  final int? mtu;
}

class DisconnectResponse {
  const DisconnectResponse({
    required this.connectionId,
    required this.status,
  });

  factory DisconnectResponse.fromJson(Map<String, dynamic> json) =>
      DisconnectResponse(
        connectionId: json['connectionId'] as String,
        status: json['status'] as String,
      );

  final String connectionId;
  final String status;
}
