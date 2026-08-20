import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vpnapp/features/countries/domain/country.dart';
import 'package:vpnapp/features/vpn/domain/vpn_controller.dart';
import 'package:vpnapp/features/vpn/domain/vpn_status.dart';
import 'package:vpnapp/platform/vpn/android_vpn_controller.dart';
import 'package:vpnapp/platform/vpn/vpn_messages.g.dart' as messages;

class _FakeVpnHostApi extends messages.VpnHostApi {
  _FakeVpnHostApi({this.onConnect}) : super();

  final Future<messages.VpnConnectResult>
      Function(messages.VpnConnectConfig config)? onConnect;

  int connectCalls = 0;
  int disconnectCalls = 0;
  messages.VpnConnectConfig? lastConfig;

  @override
  Future<messages.VpnConnectResult> connect(messages.VpnConnectConfig config) {
    connectCalls++;
    lastConfig = config;
    if (onConnect != null) {
      return onConnect!(config);
    }
    return Future.value(messages.VpnConnectResult(success: true));
  }

  @override
  Future<void> disconnect() {
    disconnectCalls++;
    return Future.value();
  }
}

void main() {
  const france = Country(code: 'FR', name: 'France', flag: '🇫🇷');

  StreamController<messages.VpnStatusEvent> events() =>
      StreamController<messages.VpnStatusEvent>.broadcast(sync: true);

  group('AndroidVpnController', () {
    test('état initial : disconnected, sans connexion, pas de simulation', () {
      final fake = _FakeVpnHostApi();
      final controller =
          AndroidVpnController(hostApi: fake, statusEvents: () => events().stream);

      expect(controller.status, VpnStatus.disconnected);
      expect(controller.currentConnection, isNull);
      expect(controller.isSimulation, isFalse);
    });

    test('connect transmet la config et suit connecting → connected', () async {
      final fake = _FakeVpnHostApi();
      final stream = events();
      final controller =
          AndroidVpnController(hostApi: fake, statusEvents: () => stream.stream);
      final snapshots = <VpnSnapshot>[];
      final subscription = controller.stream.listen(snapshots.add);

      await controller.connect(france);

      expect(fake.connectCalls, 1);
      expect(fake.lastConfig?.countryCode, 'FR');
      expect(fake.lastConfig?.serverName, 'France — Serveur');

      stream.add(messages.VpnStatusEvent(state: messages.VpnAndroidState.connecting));
      stream.add(messages.VpnStatusEvent(state: messages.VpnAndroidState.connected));

      expect(snapshots.map((s) => s.status).toList(),
          [VpnStatus.connecting, VpnStatus.connected]);
      expect(controller.status, VpnStatus.connected);
      final connection = controller.currentConnection;
      expect(connection, isNotNull);
      expect(connection!.country.code, 'FR');

      await subscription.cancel();
      await stream.close();
    });

    test('disconnect délégué au natif et suit disconnecting → disconnected',
        () async {
      final fake = _FakeVpnHostApi();
      final stream = events();
      final controller =
          AndroidVpnController(hostApi: fake, statusEvents: () => stream.stream);
      final snapshots = <VpnSnapshot>[];
      final subscription = controller.stream.listen(snapshots.add);

      await controller.connect(france);
      stream.add(messages.VpnStatusEvent(state: messages.VpnAndroidState.connected));
      snapshots.clear();

      await controller.disconnect();
      stream.add(messages.VpnStatusEvent(state: messages.VpnAndroidState.disconnecting));
      stream.add(messages.VpnStatusEvent(state: messages.VpnAndroidState.disconnected));

      expect(fake.disconnectCalls, 1);
      expect(snapshots.map((s) => s.status).toList(),
          [VpnStatus.disconnecting, VpnStatus.disconnected]);
      expect(controller.status, VpnStatus.disconnected);
      expect(controller.currentConnection, isNull);

      await subscription.cancel();
      await stream.close();
    });

    test('événement error → statut error avec message', () async {
      final fake = _FakeVpnHostApi();
      final stream = events();
      final controller =
          AndroidVpnController(hostApi: fake, statusEvents: () => stream.stream);
      final snapshots = <VpnSnapshot>[];
      final subscription = controller.stream.listen(snapshots.add);

      await controller.connect(france);
      stream.add(messages.VpnStatusEvent(
        state: messages.VpnAndroidState.error,
        message: 'TUN refusé',
      ));

      expect(controller.status, VpnStatus.error);
      expect(snapshots.last.errorMessage, 'TUN refusé');
      expect(controller.currentConnection, isNull);

      await subscription.cancel();
      await stream.close();
    });

    test('échec natif → statut error sans événement natif', () async {
      final fake = _FakeVpnHostApi(
        onConnect: (_) async =>
            messages.VpnConnectResult(success: false, message: 'Échec interne'),
      );
      final stream = events();
      final controller =
          AndroidVpnController(hostApi: fake, statusEvents: () => stream.stream);
      final snapshots = <VpnSnapshot>[];
      final subscription = controller.stream.listen(snapshots.add);

      await controller.connect(france);

      expect(controller.status, VpnStatus.error);
      expect(snapshots.single.errorMessage, 'Échec interne');

      await subscription.cancel();
      await stream.close();
    });

    test('VPN_NOT_PREPARED : aucune erreur, l’état vient du flux', () async {
      final fake = _FakeVpnHostApi(
        onConnect: (_) async =>
            messages.VpnConnectResult(success: false, message: 'VPN_NOT_PREPARED'),
      );
      final stream = events();
      final controller =
          AndroidVpnController(hostApi: fake, statusEvents: () => stream.stream);
      final snapshots = <VpnSnapshot>[];
      final subscription = controller.stream.listen(snapshots.add);

      await controller.connect(france);

      expect(controller.status, VpnStatus.disconnected);
      expect(snapshots, isEmpty);

      stream.add(messages.VpnStatusEvent(state: messages.VpnAndroidState.connected));
      expect(controller.status, VpnStatus.connected);

      await subscription.cancel();
      await stream.close();
    });
  });
}
