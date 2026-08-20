# Architecture — Projet VPN

## 1. Vue d'ensemble

```
                APPLICATION FLUTTER
                     |
                     v
            VpnController (abstrait)
            +-----------+-----------+
            |                       |
    WebMockVpnController     AndroidVpnController (Phase 2)
    (simulation seule)            |
                                  v
                        Kotlin natif → Android VpnService → WireGuard (Phase 4)
```

```
                APPLICATION FLUTTER
                     |
                     v
                  API Client (Dio)
                     |
                     v
                 BACKEND (Fastify)
                     |
                     v
              VPN Provider Orchestrator
              (multi-provider, phases suivantes)
                     |
                     v
                 VPN SERVER → INTERNET
```

## 2. Décision technologique

**Flutter (UI, state, API, Web) + Kotlin natif (couche VPN Android uniquement).**

- La couche VPN système ne peut pas être reproduite en Dart pur : `VpnService` et
  WireGuard sont Android-natifs.
- Flutter apporte l'UI, la navigation, la gestion d'état et surtout le **test Web**
  (`flutter run -d chrome`).
- L'abstraction `VpnController` isole le domaine Flutter de toute dépendance Kotlin.

## 3. Architecture Flutter

```
lib/
├── main.dart                     → ProviderScope + VpnApp
├── app.dart                      → MaterialApp.router (GoRouter)
├── core/
│   ├── api/                      → ApiClient (Dio), ApiException
│   ├── config/                   → AppConfig (URL API via --dart-define)
│   └── theme/                    → AppTheme
├── features/
│   ├── home/presentation/        → écran principal (connexion/déconnexion)
│   ├── countries/
│   │   ├── domain/               → Country (modèle pur Dart)
│   │   ├── data/                 → CountriesRepository (API)
│   │   └── presentation/         → écran de sélection des pays
│   └── vpn/
│       ├── domain/               → VpnStatus, VpnConnectionInfo, VpnController
│       ├── controller/           → providers Riverpod (vpnSnapshotProvider)
│       └── presentation/         → widgets d'état VPN
└── platform/
    └── vpn/web_mock_vpn_controller.dart
```

### Règles

- Le domaine (`domain/`) n'importe rien de Flutter ni de Kotlin → testable en pur Dart.
- L'UI ne parle jamais à Dio : UI → Provider → Repository → ApiClient.
- Le `VpnController` abstrait est le seul point d'entrée VPN pour l'UI.

## 4. VpnController et états

```dart
abstract class VpnController {
  VpnStatus get status;
  VpnConnectionInfo? get currentConnection;
  bool get isSimulation;
  Stream<VpnSnapshot> get stream;
  Future<void> connect(Country country);
  Future<void> disconnect();
}
```

États : `disconnected → connecting → connected → disconnecting → disconnected`,
plus `error`.

**WebMockVpnController** (Phase 1) : simule ces transitions avec délais réalistes,
latence simulée et erreur injectable (`failNextConnect`). Marqué `isSimulation`.

> ⚠️ **Flutter Web ne crée jamais de vrai tunnel VPN.** L'UI affiche un badge
> « MODE SIMULATION ». L'implémentation Android réelle arrive en Phase 2
> (`AndroidVpnController` via Pigeon + `VpnService`).

## 5. Communication Flutter ↔ Kotlin (Phase 2 — implémentée)

- **Pigeon 27** génère les messages typés à partir de `app/pigeon/vpn_messages.dart` :
  - `VpnConnectConfig`, `VpnConnectResult`, `VpnStatusEvent`, `VpnAndroidState` ;
  - `VpnHostApi` (interface Kotlin : `connect`, `disconnect`) ;
  - `@EventChannelApi` `VpnEventsApi.statusEvents` → Stream Dart alimenté par le natif.
- Côté Kotlin : `VpnEngine` (machine à états pure, testée), `VpnRuntime`
  (coordinateur + canal d'événements), `VpnMessenger` (impl Pigeon),
  `MainVpnService` (VpnService réel, TUN établi sans route globale en Phase 2),
  `MainActivity` (consentement `VpnService.prepare` via `onActivityResult`).
- Côté Dart : `AndroidVpnController` implémente `VpnController` (isSimulation=false).
- Régénération du code après modification des messages :

```powershell
cd app
flutter pub get
dart run pigeon --input pigeon/vpn_messages.dart
```

## 6. Backend

- **Node.js + TypeScript (strict) + Fastify + Prisma + PostgreSQL + Vitest.**
- Endpoints Phase 1 : `GET /health`, `GET /countries` (liste statique en mémoire).
- Les pays de démonstration restent **en mémoire** : aucune table multi-provider
  prématurée n'est créée.
- Prisma est configuré (`prisma/schema.prisma` sans modèle) et connecté à la base
  `vpn` (voir `scripts/check-db.ts`).

## 7. Multi-provider (phases suivantes)

```
VpnProvider (interface)
├── ProviderA
├── ProviderB
└── ProviderC
```

Le backend devra exposer : pays, serveurs, protocoles, santé, capacité, métriques,
configuration. Un registre permettra d'ajouter/désactiver un provider ou un serveur
**sans toucher à l'application Flutter**.

## 8. Sécurité (principes)

- Aucun secret fournisseur dans le code Dart, les assets, l'APK ou le build Web.
- Secrets uniquement dans `backend/.env` (gitignoré).
- Aucune clé privée WireGuard en Phase 1.
- HTTPS seul en production ; CORS restreint hors développement.
- Aucun contournement des protections Android ni des politiques Google Play.

## 9. Roadmap

| Phase | Contenu |
|---|---|
| 0 | Audit + architecture (fait) |
| 1 | Bootstrap, environnement, backend minimal, mock Web (fait) |
| 2 | Pigeon, `AndroidVpnController`, `VpnService`, flux d'événements, tests Android natifs (fait) |
| 3 | API pays/serveurs, sélection simple, config signée, auth minimale |
| 4 | WireGuard (clé privée générée côté appareil, backend = peer uniquement) |
| 5 | Multi-provider, quotas, logs, admin |
| 6 | Publication Google Play, i18n |

## 10. Identité temporaire de l'application

- Application ID temporaire : **`com.vpnproj.vpnapp`** (dossier `app/android/`).
- Valeur non définitive, à remplacer par le domaine officiel avant publication.
