import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../countries/data/countries_providers.dart';
import '../../countries/domain/country.dart';
import '../../vpn/controller/vpn_providers.dart';
import '../../vpn/domain/vpn_controller.dart';
import '../../vpn/domain/vpn_status.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen(countriesProvider, (previous, next) {
      if (!next.hasValue) {
        return;
      }
      final countries = next.value!;
      if (countries.isEmpty || ref.read(selectedCountryProvider) != null) {
        return;
      }
      final france =
          countries.where((country) => country.code == 'FR').toList();
      ref.read(selectedCountryProvider.notifier).select(
            france.isNotEmpty ? france.first : countries.first,
          );
    });

    final countriesAsync = ref.watch(countriesProvider);
    final selected = ref.watch(selectedCountryProvider);
    final snapshot = ref.watch(vpnSnapshotProvider);
    final controller = ref.watch(vpnControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('VPN'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (controller.isSimulation) const _SimulationBadge(),
                const SizedBox(height: 24),
                _CountryCard(
                  country: selected,
                  loading: countriesAsync.isLoading,
                  onTap: () => context.push('/countries'),
                ),
                const SizedBox(height: 24),
                _StatusCard(snapshot: snapshot),
                const SizedBox(height: 24),
                _ConnectButton(
                  snapshot: snapshot,
                  enabled: selected != null,
                  onPressed: _toggleConnection,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleConnection() async {
    final snapshot = ref.read(vpnSnapshotProvider);
    final notifier = ref.read(vpnSnapshotProvider.notifier);
    if (snapshot.status == VpnStatus.connected) {
      await notifier.disconnect();
      return;
    }
    final country = ref.read(selectedCountryProvider);
    if (country != null) {
      await notifier.connect(country);
    }
  }
}

class _SimulationBadge extends StatelessWidget {
  const _SimulationBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade700),
      ),
      child: const Text(
        'MODE SIMULATION',
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7A4D00)),
      ),
    );
  }
}

class _CountryCard extends StatelessWidget {
  const _CountryCard({
    required this.country,
    required this.loading,
    required this.onTap,
  });

  final Country? country;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: country == null
            ? const Icon(Icons.public)
            : Text(country!.flag, style: const TextStyle(fontSize: 28)),
        title: Text(
          country == null
              ? (loading ? 'Chargement…' : 'Aucun pays')
              : country!.name,
        ),
        subtitle: const Text('Pays sélectionné'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.snapshot});

  final VpnSnapshot snapshot;

  String get _label => switch (snapshot.status) {
        VpnStatus.disconnected => 'Déconnecté',
        VpnStatus.connecting => 'Connexion…',
        VpnStatus.connected => 'Connecté',
        VpnStatus.disconnecting => 'Déconnexion…',
        VpnStatus.error => 'Erreur',
      };

  bool get _busy =>
      snapshot.status == VpnStatus.connecting ||
      snapshot.status == VpnStatus.disconnecting;

  Color _statusColor(ColorScheme scheme) => switch (snapshot.status) {
        VpnStatus.connected => Colors.green,
        VpnStatus.error => scheme.error,
        _ => scheme.primary,
      };

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final connection = snapshot.connection;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_busy) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  _label,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: _statusColor(scheme)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (connection != null) ...[
              Text('Serveur : ${connection.serverName}'),
              const SizedBox(height: 4),
              Text('Latence : ${connection.latencyMs} ms'),
              const SizedBox(height: 4),
              Text('Connecté depuis : ${_formatTime(connection.connectedAt)}'),
            ],
            if (snapshot.status == VpnStatus.error &&
                snapshot.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  snapshot.errorMessage!,
                  style: TextStyle(color: scheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({
    required this.snapshot,
    required this.enabled,
    required this.onPressed,
  });

  final VpnSnapshot snapshot;
  final bool enabled;
  final VoidCallback onPressed;

  bool get _busy =>
      snapshot.status == VpnStatus.connecting ||
      snapshot.status == VpnStatus.disconnecting;

  @override
  Widget build(BuildContext context) {
    final connected = snapshot.status == VpnStatus.connected;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: (enabled && !_busy) ? onPressed : null,
        style: connected
            ? FilledButton.styleFrom(backgroundColor: Colors.red.shade600)
            : null,
        child: Text(connected ? 'DÉCONNECTER' : 'CONNECTER'),
      ),
    );
  }
}
