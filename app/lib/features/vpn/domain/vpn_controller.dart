import '../../countries/domain/country.dart';
import 'vpn_connection_info.dart';
import 'vpn_status.dart';

class VpnSnapshot {
  const VpnSnapshot({required this.status, this.connection, this.errorMessage});

  final VpnStatus status;
  final VpnConnectionInfo? connection;
  final String? errorMessage;
}

abstract class VpnController {
  VpnStatus get status;

  VpnConnectionInfo? get currentConnection;

  bool get isSimulation;

  Stream<VpnSnapshot> get stream;

  Future<void> connect(Country country);

  Future<void> disconnect();

  void dispose();
}
