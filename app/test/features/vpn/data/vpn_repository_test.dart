import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vpnapp/core/api/api_client.dart';
import 'package:vpnapp/core/api/api_exception.dart';
import 'package:vpnapp/features/vpn/data/vpn_repository.dart';

import '../../../helpers/fake_http_adapter.dart';

void main() {
  ApiClient clientWith({required int statusCode, required Object jsonBody}) {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.httpClientAdapter =
        FakeHttpAdapter(statusCode: statusCode, jsonBody: jsonBody);
    return ApiClient(dio: dio);
  }

  group('VpnRepository', () {
    test('fetchServersForCountry mappe la réponse', () async {
      final repository = VpnRepository(
        apiClient: clientWith(statusCode: 200, jsonBody: {
          'country': {'code': 'FR', 'name': 'France', 'flag': '🇫🇷'},
          'servers': [
            {'id': 'fr-01', 'name': 'demo-fr-01', 'provider': 'DemoProviderA'},
            {'id': 'fr-02', 'name': 'demo-fr-02', 'provider': 'DemoProviderB'},
          ],
        }),
      );

      final result = await repository.fetchServersForCountry('FR');
      expect(result.country.code, 'FR');
      expect(result.servers, hasLength(2));
      expect(result.servers.first.name, 'demo-fr-01');
    });

    test('connect mappe la réponse', () async {
      final repository = VpnRepository(
        apiClient: clientWith(statusCode: 200, jsonBody: {
          'connectionId': 'uuid-123',
          'country': 'FR',
          'server': {'id': 'fr-01', 'name': 'demo-fr-01'},
          'protocol': 'DEMO',
          'status': 'READY',
          'expiresAt': '2026-01-01T00:00:00.000Z',
        }),
      );

      final response = await repository.connect('FR');
      expect(response.connectionId, 'uuid-123');
      expect(response.server.name, 'demo-fr-01');
      expect(response.protocol, 'DEMO');
    });

    test('disconnect mappe la réponse', () async {
      final repository = VpnRepository(
        apiClient: clientWith(statusCode: 200, jsonBody: {
          'connectionId': 'uuid-123',
          'status': 'DISCONNECTED',
        }),
      );

      final response = await repository.disconnect('uuid-123');
      expect(response.connectionId, 'uuid-123');
      expect(response.status, 'DISCONNECTED');
    });

    test('fetchServersForCountry lève FormatException si réponse invalide',
        () async {
      final repository = VpnRepository(
        apiClient: clientWith(statusCode: 200, jsonBody: 'invalid'),
      );

      await expectLater(
        repository.fetchServersForCountry('FR'),
        throwsA(isA<FormatException>()),
      );
    });

    test('connect lève FormatException si réponse invalide', () async {
      final repository = VpnRepository(
        apiClient: clientWith(statusCode: 200, jsonBody: [1, 2, 3]),
      );

      await expectLater(
        repository.connect('FR'),
        throwsA(isA<FormatException>()),
      );
    });

    test('connect lève ApiException si le pays n\'existe pas', () async {
      final repository = VpnRepository(
        apiClient: clientWith(statusCode: 404, jsonBody: {
          'error': 'Country not found',
          'message': 'Aucun pays trouvé pour le code XX',
        }),
      );

      await expectLater(
        repository.connect('XX'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
