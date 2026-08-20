import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform/vpn/android_vpn_controller.dart';
import '../../../platform/vpn/web_mock_vpn_controller.dart';
import '../../countries/domain/country.dart';
import '../domain/vpn_controller.dart';

final vpnControllerProvider = Provider<VpnController>((ref) {
  final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  final VpnController controller = isAndroid
      ? AndroidVpnController()
      : WebMockVpnController();

  ref.onDispose(() => controller.dispose());
  return controller;
});

final vpnSnapshotProvider =
    NotifierProvider<VpnSnapshotNotifier, VpnSnapshot>(VpnSnapshotNotifier.new);

class VpnSnapshotNotifier extends Notifier<VpnSnapshot> {
  @override
  VpnSnapshot build() {
    final controller = ref.watch(vpnControllerProvider);
    final subscription = controller.stream.listen(
      (snapshot) => state = snapshot,
    );
    ref.onDispose(subscription.cancel);
    return VpnSnapshot(
      status: controller.status,
      connection: controller.currentConnection,
    );
  }

  Future<void> connect(Country country) =>
      ref.read(vpnControllerProvider).connect(country);

  Future<void> disconnect() => ref.read(vpnControllerProvider).disconnect();
}
