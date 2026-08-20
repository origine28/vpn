import '../../countries/domain/country.dart';

class VpnConnectionInfo {
  const VpnConnectionInfo({
    required this.country,
    required this.serverName,
    required this.latencyMs,
    required this.connectedAt,
  });

  final Country country;
  final String serverName;
  final int latencyMs;
  final DateTime connectedAt;
}
