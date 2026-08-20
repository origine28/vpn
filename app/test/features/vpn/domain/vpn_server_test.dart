import 'package:flutter_test/flutter_test.dart';
import 'package:vpnapp/features/vpn/domain/vpn_server.dart';

void main() {
  group('VpnServer', () {
    test('fromJson mappe tous les champs', () {
      final json = {
        'id': 'fr-01',
        'name': 'demo-fr-01',
        'provider': 'DemoProviderA',
      };
      final server = VpnServer.fromJson(json);
      expect(server.id, 'fr-01');
      expect(server.name, 'demo-fr-01');
      expect(server.provider, 'DemoProviderA');
    });

    test('toJson sérialise tous les champs', () {
      const server = VpnServer(
        id: 'de-01',
        name: 'demo-de-01',
        provider: 'DemoProviderB',
      );
      expect(server.toJson(), {
        'id': 'de-01',
        'name': 'demo-de-01',
        'provider': 'DemoProviderB',
      });
    });
  });

  group('CountryServers', () {
    test('fromJson mappe le pays et les serveurs', () {
      final json = {
        'country': {'code': 'FR', 'name': 'France', 'flag': '🇫🇷'},
        'servers': [
          {'id': 'fr-01', 'name': 'demo-fr-01', 'provider': 'DemoProviderA'},
          {'id': 'fr-02', 'name': 'demo-fr-02', 'provider': 'DemoProviderB'},
        ],
      };
      final result = CountryServers.fromJson(json);
      expect(result.country.code, 'FR');
      expect(result.country.name, 'France');
      expect(result.servers, hasLength(2));
      expect(result.servers.first.name, 'demo-fr-01');
    });
  });
}
