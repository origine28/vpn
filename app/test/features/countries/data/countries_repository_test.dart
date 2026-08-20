import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vpnapp/core/api/api_client.dart';
import 'package:vpnapp/features/countries/data/countries_repository.dart';

import '../../../helpers/fake_http_adapter.dart';

void main() {
  ApiClient clientWith({required int statusCode, required Object jsonBody}) {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.httpClientAdapter =
        FakeHttpAdapter(statusCode: statusCode, jsonBody: jsonBody);
    return ApiClient(dio: dio);
  }

  group('CountriesRepository', () {
    test('fetchCountries mappe la réponse GET /countries', () async {
      final repository = CountriesRepository(
        apiClient: clientWith(statusCode: 200, jsonBody: [
          {'code': 'FR', 'name': 'France', 'flag': '🇫🇷'},
          {'code': 'DE', 'name': 'Allemagne', 'flag': '🇩🇪'},
        ]),
      );

      final countries = await repository.fetchCountries();

      expect(countries, hasLength(2));
      expect(countries.first.code, 'FR');
      expect(countries.first.name, 'France');
      expect(countries.last.code, 'DE');
    });

    test('fetchCountries lève une FormatException si le corps n’est pas une liste', () async {
      final repository = CountriesRepository(
        apiClient: clientWith(statusCode: 200, jsonBody: {'unexpected': true}),
      );

      await expectLater(
        repository.fetchCountries(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
