import '../../../core/api/api_client.dart';
import '../domain/country.dart';

class CountriesRepository {
  CountriesRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<Country>> fetchCountries() async {
    final data = await apiClient.get('/countries');
    if (data is! List) {
      throw const FormatException('Réponse /countries invalide');
    }
    return data
        .map((item) => Country.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
