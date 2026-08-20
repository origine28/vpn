import 'package:flutter_test/flutter_test.dart';
import 'package:vpnapp/features/vpn/domain/vpn_connection_response.dart';

void main() {
  group('VpnConnectionResponse', () {
    test('fromJson mappe tous les champs', () {
      final json = {
        'connectionId': 'uuid-123',
        'country': 'FR',
        'server': {'id': 'fr-01', 'name': 'demo-fr-01'},
        'protocol': 'DEMO',
        'status': 'READY',
        'expiresAt': '2026-01-01T00:00:00.000Z',
      };
      final response = VpnConnectionResponse.fromJson(json);
      expect(response.connectionId, 'uuid-123');
      expect(response.country, 'FR');
      expect(response.server.id, 'fr-01');
      expect(response.server.name, 'demo-fr-01');
      expect(response.protocol, 'DEMO');
      expect(response.status, 'READY');
      expect(response.expiresAt, '2026-01-01T00:00:00.000Z');
    });

    test('ne contient pas de secrets', () {
      final json = {
        'connectionId': 'uuid-123',
        'country': 'FR',
        'server': {'id': 'fr-01', 'name': 'demo-fr-01'},
        'protocol': 'DEMO',
        'status': 'READY',
        'expiresAt': '2026-01-01T00:00:00.000Z',
      };
      final response = VpnConnectionResponse.fromJson(json);
      expect(response.connectionId, isNot(contains('privateKey')));
      expect(response.connectionId, isNot(contains('secret')));
    });
  });

  group('DisconnectResponse', () {
    test('fromJson mappe tous les champs', () {
      final json = {
        'connectionId': 'uuid-123',
        'status': 'DISCONNECTED',
      };
      final response = DisconnectResponse.fromJson(json);
      expect(response.connectionId, 'uuid-123');
      expect(response.status, 'DISCONNECTED');
    });
  });
}
