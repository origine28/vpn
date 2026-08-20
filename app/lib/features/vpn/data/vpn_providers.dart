import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../countries/data/countries_providers.dart';
import '../domain/vpn_server.dart';
import 'vpn_repository.dart';

final vpnRepositoryProvider = Provider<VpnRepository>(
  (ref) => VpnRepository(apiClient: ref.watch(apiClientProvider)),
);

final serversForCountryProvider =
    FutureProvider.family<CountryServers, String>((ref, countryCode) async {
  final repository = ref.watch(vpnRepositoryProvider);
  return repository.fetchServersForCountry(countryCode);
});

final vpnConnectionProvider =
    NotifierProvider<VpnConnectionNotifier, VpnConnectionState>(
  VpnConnectionNotifier.new,
);

class VpnConnectionState {
  const VpnConnectionState({
    this.connectionId,
    this.serverName,
    this.status = 'idle',
    this.error,
  });

  final String? connectionId;
  final String? serverName;
  final String status;
  final String? error;

  bool get isConnected => status == 'READY';
  bool get isConnecting => status == 'connecting';
  bool get isDisconnecting => status == 'disconnecting';
  bool get isError => status == 'error';
  bool get isIdle => status == 'idle';
}

class VpnConnectionNotifier extends Notifier<VpnConnectionState> {
  @override
  VpnConnectionState build() => const VpnConnectionState();

  Future<void> connect(String countryCode) async {
    state = const VpnConnectionState(status: 'connecting');

    try {
      final repository = ref.read(vpnRepositoryProvider);
      final response = await repository.connect(countryCode);
      state = VpnConnectionState(
        connectionId: response.connectionId,
        serverName: response.server.name,
        status: response.status,
      );
    } catch (e) {
      state = VpnConnectionState(
        status: 'error',
        error: e.toString(),
      );
    }
  }

  Future<void> disconnect() async {
    final connectionId = state.connectionId;
    if (connectionId == null) {
      state = const VpnConnectionState(status: 'idle');
      return;
    }

    state = VpnConnectionState(
      connectionId: connectionId,
      serverName: state.serverName,
      status: 'disconnecting',
    );

    try {
      final repository = ref.read(vpnRepositoryProvider);
      await repository.disconnect(connectionId);
      state = const VpnConnectionState(status: 'idle');
    } catch (e) {
      state = VpnConnectionState(
        status: 'error',
        error: e.toString(),
      );
    }
  }
}
