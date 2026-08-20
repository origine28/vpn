import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/country.dart';
import 'countries_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final countriesRepositoryProvider = Provider<CountriesRepository>(
  (ref) => CountriesRepository(apiClient: ref.watch(apiClientProvider)),
);

final countriesProvider = FutureProvider<List<Country>>(
  (ref) => ref.watch(countriesRepositoryProvider).fetchCountries(),
);

final selectedCountryProvider =
    NotifierProvider<SelectedCountryNotifier, Country?>(SelectedCountryNotifier.new);

class SelectedCountryNotifier extends Notifier<Country?> {
  @override
  Country? build() => null;

  void select(Country country) => state = country;
}
