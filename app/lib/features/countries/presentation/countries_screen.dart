import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/countries_providers.dart';
import '../domain/country.dart';

class CountriesScreen extends ConsumerWidget {
  const CountriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countriesAsync = ref.watch(countriesProvider);
    final selected = ref.watch(selectedCountryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Choisir un pays')),
      body: countriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ErrorView(
          onRetry: () => ref.invalidate(countriesProvider),
        ),
        data: (countries) => ListView.separated(
          itemCount: countries.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final country = countries[index];
            return _CountryTile(
              country: country,
              selected: country.code == selected?.code,
              onTap: () {
                ref.read(selectedCountryProvider.notifier).select(country);
                context.pop();
              },
            );
          },
        ),
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.country,
    required this.selected,
    required this.onTap,
  });

  final Country country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
      title: Text(country.name),
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: onTap,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Impossible de charger les pays.'),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
