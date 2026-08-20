import 'package:flutter_test/flutter_test.dart';
import 'package:vpnapp/features/vpn/domain/vpn_connection_response.dart';

void main() {
  group('WireGuardServerConfig', () {
    test('fromJson mappe tous les champs', () {
      final json = {
        'serverPublicKey': 'DemoServerPublicKey12345678901234567890=',
        'serverEndpoint': 'demo.wireguard.example.com:51820',
        'allowedIPs': ['0.0.0.0/0', '::/0'],
        'dnsServer': '1.1.1.1',
        'clientAddress': '10.8.0.2/32',
        'mtu': 1420,
      };
      final config = WireGuardServerConfig.fromJson(json);
      expect(config.serverPublicKey, 'DemoServerPublicKey12345678901234567890=');
      expect(config.serverEndpoint, 'demo.wireguard.example.com:51820');
      expect(config.allowedIPs, ['0.0.0.0/0', '::/0']);
      expect(config.dnsServer, '1.1.1.1');
      expect(config.clientAddress, '10.8.0.2/32');
      expect(config.mtu, 1420);
    });

    test('fromJson gère les champs optionnels', () {
      final json = {
        'serverPublicKey': 'key123',
        'serverEndpoint': '1.2.3.4:51820',
      };
      final config = WireGuardServerConfig.fromJson(json);
      expect(config.serverPublicKey, 'key123');
      expect(config.serverEndpoint, '1.2.3.4:51820');
      expect(config.allowedIPs, isNull);
      expect(config.dnsServer, isNull);
      expect(config.clientAddress, isNull);
      expect(config.mtu, isNull);
    });

    test('ne contient pas de clé privée', () {
      final config = WireGuardServerConfig(
        serverPublicKey: 'pubkey',
        serverEndpoint: 'host:port',
      );
      expect(config.serverPublicKey, isNot(contains('private')));
    });
  });

  group('VpnConnectionResponse with WireGuard', () {
    test('parse la réponse avec wireguard', () {
      final json = {
        'connectionId': 'uuid-123',
        'country': 'FR',
        'server': {'id': 'fr-01', 'name': 'demo-fr-01'},
        'protocol': 'DEMO',
        'status': 'READY',
        'expiresAt': '2026-01-01T00:00:00.000Z',
        'wireguard': {
          'serverPublicKey': 'DemoServerPublicKey12345678901234567890=',
          'serverEndpoint': 'demo.wireguard.example.com:51820',
          'allowedIPs': ['0.0.0.0/0'],
          'dnsServer': '1.1.1.1',
          'clientAddress': '10.8.0.2/32',
          'mtu': 1420,
        },
        'mode': 'SIMULATION',
      };
      final response = VpnConnectionResponse.fromJson(json);
      expect(response.wireguard, isNotNull);
      expect(response.wireguard!.serverPublicKey, contains('Demo'));
      expect(response.wireguard!.serverEndpoint, contains('51820'));
      expect(response.wireguard!.clientAddress, '10.8.0.2/32');
      expect(response.mode, 'SIMULATION');
    });

    test('parse la réponse sans wireguard (Phase 3)', () {
      final json = {
        'connectionId': 'uuid-123',
        'country': 'FR',
        'server': {'id': 'fr-01', 'name': 'demo-fr-01'},
        'protocol': 'DEMO',
        'status': 'READY',
        'expiresAt': '2026-01-01T00:00:00.000Z',
      };
      final response = VpnConnectionResponse.fromJson(json);
      expect(response.wireguard, isNull);
      expect(response.mode, isNull);
    });

    test('parse mode LIVE', () {
      final json = {
        'connectionId': 'uuid-456',
        'country': 'US',
        'server': {'id': 'us-01', 'name': 'vpn-us-01'},
        'protocol': 'WIREGUARD',
        'status': 'READY',
        'expiresAt': '2026-01-01T00:00:00.000Z',
        'wireguard': {
          'serverPublicKey': 'RealServerPublicKey1234567890123456789=',
          'serverEndpoint': 'vpn.example.com:51820',
          'allowedIPs': ['0.0.0.0/0'],
          'dnsServer': '1.1.1.1',
          'clientAddress': '10.8.0.3/32',
          'mtu': 1420,
        },
        'mode': 'LIVE',
      };
      final response = VpnConnectionResponse.fromJson(json);
      expect(response.mode, 'LIVE');
      expect(response.wireguard!.serverEndpoint, 'vpn.example.com:51820');
    });
  });
}
