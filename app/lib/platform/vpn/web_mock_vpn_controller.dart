import 'dart:async';

import '../../features/countries/domain/country.dart';
import '../../features/vpn/domain/vpn_connection_info.dart';
import '../../features/vpn/domain/vpn_controller.dart';
import '../../features/vpn/domain/vpn_status.dart';

class WebMockVpnController implements VpnController {
  WebMockVpnController({
    this.connectDelay = const Duration(milliseconds: 900),
    this.disconnectDelay = const Duration(milliseconds: 500),
    this.latencyMs = 42,
    this.failNextConnect = false,
  });

  final Duration connectDelay;
  final Duration disconnectDelay;
  final int latencyMs;
  bool failNextConnect;

  VpnStatus _status = VpnStatus.disconnected;
  VpnConnectionInfo? _connection;
  final StreamController<VpnSnapshot> _controller =
      StreamController<VpnSnapshot>.broadcast(sync: true);

  @override
  VpnStatus get status => _status;

  @override
  VpnConnectionInfo? get currentConnection => _connection;

  @override
  bool get isSimulation => true;

  @override
  Stream<VpnSnapshot> get stream => _controller.stream;

  @override
  Future<void> connect(Country country) async {
    _setStatus(VpnStatus.connecting);
    await Future<void>.delayed(connectDelay);

    if (failNextConnect) {
      failNextConnect = false;
      _connection = null;
      _setStatus(VpnStatus.error, errorMessage: 'Serveur indisponible (simulation)');
      return;
    }

    _connection = VpnConnectionInfo(
      country: country,
      serverName: '${country.name} — Demo',
      latencyMs: latencyMs,
      connectedAt: DateTime.now(),
    );
    _setStatus(VpnStatus.connected);
  }

  @override
  Future<void> disconnect() async {
    if (_status != VpnStatus.connected) {
      return;
    }
    _setStatus(VpnStatus.disconnecting);
    await Future<void>.delayed(disconnectDelay);

    _connection = null;
    _setStatus(VpnStatus.disconnected);
  }

  void _setStatus(VpnStatus status, {String? errorMessage}) {
    _status = status;
    _controller.add(
      VpnSnapshot(
        status: status,
        connection: _connection,
        errorMessage: errorMessage,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
  }
}
