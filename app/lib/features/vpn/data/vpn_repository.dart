import '../../../core/api/api_client.dart';
import '../domain/vpn_connection_response.dart';
import '../domain/vpn_server.dart';

class VpnRepository {
  VpnRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<CountryServers> fetchServersForCountry(String countryCode) async {
    final data = await apiClient.get('/countries/$countryCode/servers');
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Réponse /countries/:code/servers invalide');
    }
    return CountryServers.fromJson(data);
  }

  Future<VpnConnectionResponse> connect(
    String countryCode, {
    String? clientPublicKey,
  }) async {
    final data = await apiClient.post(
      '/vpn/connect',
      data: {
        'countryCode': countryCode,
        'clientPublicKey': clientPublicKey,
      },
    );
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Réponse /vpn/connect invalide');
    }
    return VpnConnectionResponse.fromJson(data);
  }

  Future<DisconnectResponse> disconnect(String connectionId) async {
    final data = await apiClient.post(
      '/vpn/disconnect',
      data: {'connectionId': connectionId},
    );
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Réponse /vpn/disconnect invalide');
    }
    return DisconnectResponse.fromJson(data);
  }
}
