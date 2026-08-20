# Rapport Phase 2 — Flutter ↔ Kotlin, VpnService, événements

**Statut :** À VALIDER.

## 1. Objectif
Rendre la couche VPN Android réelle : le contrôleur Flutter parle au natif Kotlin
via Pigeon (messages typés), le service `VpnService` établit l'interface TUN avec le
consentement système, et l'état remonte vers l'UI par un canal d'événements. Des
tests natifs Kotlin couvrent la machine à états.

## 2. Contrat typé (Pigeon 27)
- Définition : `app/pigeon/vpn_messages.dart` (`@ConfigurePigeon`, `@HostApi`, `@EventChannelApi`).
- Générés : `lib/platform/vpn/vpn_messages.g.dart` et
  `android/app/src/main/kotlin/com/vpnproj/vpnapp/vpn/VpnMessages.kt`.
- Types : `VpnConnectConfig`, `VpnConnectResult`, `VpnStatusEvent`, `VpnAndroidState`.
- API : `VpnHostApi.connect/disconnect` (Flutter → Kotlin) ;
  `VpnEventsApi.statusEvents` (Stream Kotlin → Flutter).

## 3. Côté Kotlin (package `com.vpnproj.vpnapp.vpn`)
- `VpnEngine` : machine à états pure (DISCONNECTED → CONNECTING → CONNECTED →
  DISCONNECTING → DISCONNECTED, + ERROR), testable JVM, événements via callback.
- `VpnRuntime` : coordinateur global (attache le host API et le canal d'événements,
  gère `VPN_NOT_PREPARED`, bridge les événements du moteur vers Flutter).
- `VpnMessenger` : implémentation Pigeon du `VpnHostApi`.
- `MainVpnService` : `VpnService` réel — TUN via `Builder` (MTU, adresse 10.8.0.2/32,
  DNS) ; **aucune route globale** en Phase 2 pour ne pas couper le trafic (le
  transport WireGuard arrive en Phase 4).
- `MainActivity` : consentement système via `VpnService.prepare()` et
  `startActivityForResult`/`onActivityResult`.

## 4. Côté Dart
- `lib/platform/vpn/android_vpn_controller.dart` : implémente `VpnController`
  (isSimulation=false), mappe `VpnAndroidState` → `VpnStatus`, suit le flux
  d'événements, gère l'échec `VPN_NOT_PREPARED` (dialogue système).
- `lib/features/vpn/controller/vpn_providers.dart` : sélection par plateforme
  (Android → natif, sinon mock Web).
- `VpnController` gagne `dispose()` (implémenté par les deux contrôleurs).

## 5. Tests
- **Kotlin (JUnit, `gradlew testDebugUnitTest`) : 8/8 passés** (VpnEngine :
  transitions, erreur, annulation, re-connexion après erreur, services).
- **Flutter : 18/18 passés** (12 Phase 1 + 6 nouveaux `AndroidVpnController`).
- `flutter analyze` : **No issues found**.

## 6. Validations build
- `flutter build apk --debug` → **OK** (`app-debug.apk`, ~147 Mo).
- `flutter build web` → **OK** (la simulation Web reste active).

## 7. Points d'attention rencontrés
- Pigeon 27 : syntaxe sans `Future<…>` (méthodes sync + `@async`), `@EventChannelApi`
  pour les streams ; `--help` non supporté (utiliser le `@ConfigurePigeon` in-file).
- `FlutterActivity` étend `android.app.Activity` (pas `ComponentActivity`) : pas de
  `registerForActivityResult` → `startActivityForResult`/`onActivityResult`.
- `debug.keystore` local illisible par JDK 21 (`Tag number over 30`) → régénéré.
- Premier build Gradle long (téléchargements) ; erreur `FileLockContentionHandler`
  intermittente sur Windows (relance résout).
- Espace disque : nécessité de nettoyer les zips temporaires (2,4 Go libérés).

## 8. Limites Phase 2 (volontaires)
- Pas de transport chiffré : le TUN est établi sans route globale (indicateur VPN
  système, trafic inchangé). WireGuard = Phase 4.
- Pas d'appareil/émulateur disponible : le flux complet (dialogue système, indicateur)
  n'a pas été vérifié sur matériel ; validé par build + tests unitaires.

## 9. Étapes suivantes (Phase 3)
API pays/serveurs, sélection simple, config signée, auth minimale.
