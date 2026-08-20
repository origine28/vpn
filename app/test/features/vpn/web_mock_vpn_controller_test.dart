import 'package:flutter_test/flutter_test.dart';
import 'package:vpnapp/features/countries/domain/country.dart';
import 'package:vpnapp/features/vpn/domain/vpn_status.dart';
import 'package:vpnapp/platform/vpn/web_mock_vpn_controller.dart';

void main() {
  const france = Country(code: 'FR', name: 'France', flag: '🇫🇷');

  WebMockVpnController controller({bool failNextConnect = false}) =>
      WebMockVpnController(
        connectDelay: Duration.zero,
        disconnectDelay: Duration.zero,
        latencyMs: 42,
        failNextConnect: failNextConnect,
      );

  group('WebMockVpnController', () {
    test('état initial : disconnected, sans connexion', () {
      final web = controller();
      expect(web.status, VpnStatus.disconnected);
      expect(web.currentConnection, isNull);
      expect(web.isSimulation, isTrue);
    });

    test('connect : disconnected → connecting → connected', () async {
      final web = controller();
      final events = <VpnStatus>[];
      final subscription = web.stream.listen((s) => events.add(s.status));

      await web.connect(france);

      expect(events, [VpnStatus.connecting, VpnStatus.connected]);
      expect(web.status, VpnStatus.connected);
      final connection = web.currentConnection;
      expect(connection, isNotNull);
      expect(connection!.country.code, 'FR');
      expect(connection.serverName, 'France — Demo');
      expect(connection.latencyMs, 42);
      await subscription.cancel();
    });

    test('disconnect : connected → disconnecting → disconnected', () async {
      final web = controller();
      final events = <VpnStatus>[];
      final subscription = web.stream.listen((s) => events.add(s.status));

      await web.connect(france);
      events.clear();
      await web.disconnect();

      expect(events, [VpnStatus.disconnecting, VpnStatus.disconnected]);
      expect(web.status, VpnStatus.disconnected);
      expect(web.currentConnection, isNull);
      await subscription.cancel();
    });

    test('disconnect sans connexion active ne fait rien', () async {
      final web = controller();
      final events = <VpnStatus>[];
      final subscription = web.stream.listen((s) => events.add(s.status));

      await web.disconnect();

      expect(events, isEmpty);
      expect(web.status, VpnStatus.disconnected);
      await subscription.cancel();
    });

    test('simulation d’erreur : connect → error', () async {
      final web = controller(failNextConnect: true);
      final events = <VpnStatus>[];
      final subscription = web.stream.listen((s) => events.add(s.status));

      await web.connect(france);

      expect(web.status, VpnStatus.error);
      expect(web.currentConnection, isNull);
      expect(events, [VpnStatus.connecting, VpnStatus.error]);
      await subscription.cancel();
    });
  });
}
