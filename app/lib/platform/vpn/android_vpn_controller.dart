import 'dart:async';

import '../../features/countries/domain/country.dart';
import '../../features/vpn/domain/vpn_connection_info.dart';
import '../../features/vpn/domain/vpn_controller.dart';
import '../../features/vpn/domain/vpn_status.dart';
import 'vpn_messages.g.dart' as messages;

/// Contrôleur VPN pour Android : délègue au natif Kotlin via Pigeon
/// ([messages.VpnHostApi]) et reçoit les changements d'état via le canal
/// d'événements ([messages.statusEvents]).
///
/// `isSimulation == false` : il s'agit du vrai service VPN Android.
///
/// Phase 4 : supporte la configuration WireGuard (clé serveur, endpoint).
class AndroidVpnController implements VpnController {
  AndroidVpnController({
    messages.VpnHostApi? hostApi,
    Stream<messages.VpnStatusEvent> Function()? statusEvents,
  })  : _hostApi = hostApi ?? messages.VpnHostApi(),
        _statusEvents = statusEvents ?? messages.statusEvents;

  final messages.VpnHostApi _hostApi;
  final Stream<messages.VpnStatusEvent> Function() _statusEvents;

  VpnStatus _status = VpnStatus.disconnected;
  VpnConnectionInfo? _connection;
  Country? _country;
  String? _serverName;
  StreamSubscription<messages.VpnStatusEvent>? _eventsSubscription;

  final StreamController<VpnSnapshot> _controller =
      StreamController<VpnSnapshot>.broadcast(sync: true);

  @override
  VpnStatus get status => _status;

  @override
  VpnConnectionInfo? get currentConnection => _connection;

  @override
  bool get isSimulation => false;

  @override
  Stream<VpnSnapshot> get stream => _controller.stream;

  void _ensureListening() {
    _eventsSubscription ??= _statusEvents().listen(_onStatusEvent);
  }

  void _onStatusEvent(messages.VpnStatusEvent event) {
    _status = _mapState(event.state);

    if (_status == VpnStatus.connected) {
      final country = _country;
      if (country != null) {
        _connection = VpnConnectionInfo(
          country: country,
          serverName: _serverName ?? '${country.name} — Serveur',
          latencyMs: 0,
          connectedAt: DateTime.now(),
        );
      }
    } else if (_status == VpnStatus.disconnected ||
        _status == VpnStatus.error) {
      _connection = null;
    }

    _controller.add(
      VpnSnapshot(
        status: _status,
        connection: _connection,
        errorMessage: _status == VpnStatus.error ? event.message : null,
      ),
    );
  }

  @override
  Future<void> connect(Country country) async {
    _ensureListening();
    _country = country;
    _serverName = '${country.name} — Serveur';
    final config = messages.VpnConnectConfig(
      countryCode: country.code,
      serverName: _serverName!,
    );
    final result = await _hostApi.connect(config);
    if (!result.success && result.message != 'VPN_NOT_PREPARED') {
      _status = VpnStatus.error;
      _controller.add(
        VpnSnapshot(
          status: VpnStatus.error,
          errorMessage: result.message ?? 'Échec de connexion',
        ),
      );
    }
  }

  /// Connecte avec configuration WireGuard (Phase 4).
  /// Le serveur fournit la clé publique et l'endpoint.
  /// La clé privée client est générée côté appareil.
  Future<void> connectWithWireGuard({
    required Country country,
    required String serverPublicKey,
    required String serverEndpoint,
    String? presharedKey,
    String? dnsServer,
    List<String>? allowedIPs,
  }) async {
    _ensureListening();
    _country = country;
    _serverName = '${country.name} — WireGuard';

    final config = messages.VpnConnectConfig(
      countryCode: country.code,
      serverName: _serverName!,
      serverPublicKey: serverPublicKey,
      serverEndpoint: serverEndpoint,
      presharedKey: presharedKey,
      dnsServer: dnsServer,
      allowedIPs: allowedIPs,
    );

    final result = await _hostApi.connect(config);
    if (!result.success && result.message != 'VPN_NOT_PREPARED') {
      _status = VpnStatus.error;
      _controller.add(
        VpnSnapshot(
          status: VpnStatus.error,
          errorMessage: result.message ?? 'Échec de connexion WireGuard',
        ),
      );
    }
  }

  /// Génère la configuration WireGuard côté appareil.
  /// La clé privée reste locale, seule la clé publique est retournée.
  Future<messages.WireGuardTunnelConfig> generateWireGuardConfig({
    required String serverPublicKey,
    required String serverEndpoint,
  }) async {
    final config = messages.VpnConnectConfig(
      countryCode: '',
      serverName: '',
      serverPublicKey: serverPublicKey,
      serverEndpoint: serverEndpoint,
    );
    return _hostApi.generateWireGuardConfig(config);
  }

  @override
  Future<void> disconnect() async {
    _ensureListening();
    await _hostApi.disconnect();
  }

  static VpnStatus _mapState(messages.VpnAndroidState state) {
    switch (state) {
      case messages.VpnAndroidState.disconnected:
        return VpnStatus.disconnected;
      case messages.VpnAndroidState.connecting:
        return VpnStatus.connecting;
      case messages.VpnAndroidState.connected:
        return VpnStatus.connected;
      case messages.VpnAndroidState.disconnecting:
        return VpnStatus.disconnecting;
      case messages.VpnAndroidState.error:
        return VpnStatus.error;
    }
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _controller.close();
  }
}
