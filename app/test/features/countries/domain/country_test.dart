import 'package:flutter_test/flutter_test.dart';
import 'package:vpnapp/features/countries/domain/country.dart';

void main() {
  group('Country.fromJson', () {
    test('mappe tous les champs', () {
      const json = {'code': 'FR', 'name': 'France', 'flag': '🇫🇷'};
      final country = Country.fromJson(json);
      expect(country.code, 'FR');
      expect(country.name, 'France');
      expect(country.flag, '🇫🇷');
    });

    test('toJson sérialise tous les champs', () {
      const country = Country(code: 'DE', name: 'Allemagne', flag: '🇩🇪');
      expect(country.toJson(), {
        'code': 'DE',
        'name': 'Allemagne',
        'flag': '🇩🇪',
      });
    });
  });
}
