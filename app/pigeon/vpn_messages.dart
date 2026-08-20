import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/vpn/vpn_messages.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/app/src/main/kotlin/com/vpnproj/vpnapp/vpn/VpnMessages.kt',
    kotlinOptions: KotlinOptions(package: 'com.vpnproj.vpnapp.vpn'),
    dartPackageName: 'vpnapp',
  )
)
/// État VPN vu par la couche Android (reflet de [VpnStatus] côté Dart).
enum VpnAndroidState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

/// Configuration de connexion transmise à la couche native (Kotlin).
class VpnConnectConfig {
  VpnConnectConfig({
    required this.countryCode,
    required this.serverName,
    this.serverPort,
    this.serverPublicKey,
    this.serverEndpoint,
    this.presharedKey,
    this.allowedIPs,
    this.dnsServer,
  });

  final String countryCode;
  final String serverName;
  final int? serverPort;

  /// Clé publique du serveur WireGuard (base64).
  final String? serverPublicKey;

  /// Endpoint du serveur WireGuard (host:port).
  final String? serverEndpoint;

  /// Clé pré-partagée optionnelle (base64).
  final String? presharedKey;

  /// IP autorisées (ex: "0.0.0.0/0").
  final List<String>? allowedIPs;

  /// Serveur DNS (ex: "1.1.1.1").
  final String? dnsServer;
}

/// Résultat d'un appel [VpnHostApi.connect].
class VpnConnectResult {
  VpnConnectResult({
    required this.success,
    this.message,
  });

  final bool success;
  final String? message;
}

/// Événement d'état envoyé par le natif (Kotlin) vers Flutter.
class VpnStatusEvent {
  VpnStatusEvent({
    required this.state,
    this.message,
  });

  final VpnAndroidState state;
  final String? message;
}

/// Configuration WireGuard complète retournée par le natif.
class WireGuardTunnelConfig {
  WireGuardTunnelConfig({
    required this.clientPrivateKey,
    required this.clientPublicKey,
    required this.clientAddress,
    required this.serverPublicKey,
    required this.serverEndpoint,
    this.presharedKey,
    this.allowedIPs,
    this.dnsServer,
    this.mtu,
  });

  final String clientPrivateKey;
  final String clientPublicKey;
  final String clientAddress;
  final String serverPublicKey;
  final String serverEndpoint;
  final String? presharedKey;
  final List<String>? allowedIPs;
  final String? dnsServer;
  final int? mtu;
}

/// API appelée par Flutter vers le natif (Kotlin).
@HostApi()
abstract class VpnHostApi {
  VpnConnectResult connect(VpnConnectConfig config);

  void disconnect();

  /// Génère une paire de clés WireGuard et retourne la config tunnel.
  WireGuardTunnelConfig generateWireGuardConfig(VpnConnectConfig config);
}

/// Canal d'événements : le natif (Kotlin) pousse les changements d'état
/// vers Flutter sous forme de [Stream].
@EventChannelApi()
abstract class VpnEventsApi {
  VpnStatusEvent statusEvents();
}
