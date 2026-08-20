import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vpnapp/app.dart';
import 'package:vpnapp/core/api/api_client.dart';
import 'package:vpnapp/features/countries/data/countries_providers.dart';
import 'package:vpnapp/features/vpn/controller/vpn_providers.dart';
import 'package:vpnapp/platform/vpn/web_mock_vpn_controller.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  Widget buildApp() {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.httpClientAdapter = FakeHttpAdapter(statusCode: 200, jsonBody: [
      {'code': 'FR', 'name': 'France', 'flag': '🇫🇷'},
      {'code': 'DE', 'name': 'Allemagne', 'flag': '🇩🇪'},
    ]);

    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(ApiClient(dio: dio)),
        vpnControllerProvider.overrideWithValue(
          WebMockVpnController(
            connectDelay: Duration.zero,
            disconnectDelay: Duration.zero,
          ),
        ),
      ],
      child: const VpnApp(),
    );
  }

  testWidgets('affiche le badge simulation et le bouton CONNECTER', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('MODE SIMULATION'), findsOneWidget);
    expect(find.text('Déconnecté'), findsOneWidget);
    expect(find.text('CONNECTER'), findsOneWidget);
    expect(find.text('France'), findsOneWidget);
  });

  testWidgets('connecte puis déconnecte via la simulation', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('CONNECTER'));
    await tester.pumpAndSettle();

    expect(find.text('Connecté'), findsOneWidget);
    expect(find.text('DÉCONNECTER'), findsOneWidget);
    expect(find.textContaining('France — Demo'), findsOneWidget);
    expect(find.textContaining('Latence :'), findsOneWidget);

    await tester.tap(find.text('DÉCONNECTER'));
    await tester.pumpAndSettle();

    expect(find.text('Déconnecté'), findsOneWidget);
    expect(find.text('CONNECTER'), findsOneWidget);
  });

  testWidgets('l’écran de pays permet de changer de pays', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('France'));
    await tester.pumpAndSettle();

    expect(find.text('Choisir un pays'), findsOneWidget);
    expect(find.text('Allemagne'), findsOneWidget);

    await tester.tap(find.text('Allemagne'));
    await tester.pumpAndSettle();

    expect(find.text('Choisir un pays'), findsNothing);
    expect(find.text('Allemagne'), findsOneWidget);
  });
}
