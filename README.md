# VPN — Application mobile (Android) + Flutter Web

Application VPN moderne : l'utilisateur choisit un pays, notre backend détermine le
meilleur serveur/fournisseur disponible, et le client établit la connexion.

**Architecture retenue : Flutter (UI) + Kotlin natif (couche VPN Android).**

> ⚠️ **Flutter Web utilise uniquement une simulation VPN.** Aucun vrai tunnel n'est
> créé depuis le navigateur. L'UI affiche un badge « MODE SIMULATION ».

## CURRENT PROJECT STATUS

Résumé complet dans [docs/PROJECT_STATUS.md](docs/PROJECT_STATUS.md).

## Statut

- [x] **Phase 0** — Audit et architecture (validée)
- [x] **Phase 1** — Bootstrap du projet (environnement, structure, backend minimal)
- [x] **Phase 2** — Pigeon, `AndroidVpnController`, `VpnService`, flux d'événements, tests natifs
- [x] **Phase 3** — API pays/serveurs, sélection, config (implémentée, 30+36 tests OK)
- [x] **Phase 4** — WireGuard (implémenté : KeyPair, GoBackend, Backend, Flutter — non testé E2E)
- [ ] Phase 5 — Multi-provider commercial
- [ ] Phases suivantes — voir `docs/architecture.md`

## Structure

```
projets/mobile/vpn/
├── app/          → Application Flutter (Android + Web)
│   └── lib/      → core/, features/ (home, countries, vpn), platform/ (mock web)
├── backend/      → API Fastify + TypeScript + Prisma + PostgreSQL
├── docs/         → Documentation d'architecture
└── scripts/      → Scripts utilitaires
```

## Prérequis

- Windows 10/11
- Flutter stable 3.47.0 (Dart 3.13.0)
- Android SDK (platforms;android-36, build-tools 36.0.0, platform-tools)
- JDK 21 (Temurin)
- Node.js ≥ 24 (npm 11)
- PostgreSQL 17 (service Windows local)
- Chrome (test Web)

## Installation

```powershell
# 1. Backend
cd backend
Copy-Item .env.example .env     # puis adapter DATABASE_URL
npm install
npm run prisma:generate         # génère le client Prisma (aucun modèle en Phase 1)
npm run db:check                # vérifie l'accès PostgreSQL

# 2. Application Flutter
cd ../app
flutter pub get
```

## Lancement

### Flutter Web (simulation)

```powershell
cd backend; npm run dev            # API sur http://127.0.0.1:3000
cd app; flutter run -d chrome      # UI (badge « MODE SIMULATION »)
```

### Android

```powershell
flutter run -d <android-device>    # nécessite un appareil/émulateur
```

Sur Android, la première connexion demande le consentement système
(`VpnService.prepare`) puis établit l'interface TUN (indicateur « VPN actif »).
Le transport chiffré réel (WireGuard) est implémenté mais en mode SIMULATION
(clés WireGuard non configurées). Voir `backend/.env.wireguard.example` pour
configurer un vrai serveur WireGuard.

### Régénération du code Pigeon

```powershell
cd app
dart run pigeon --input pigeon/vpn_messages.dart
```

### Backend

```powershell
npm run dev          # dev (tsx watch)
npm run build        # build TypeScript → dist/
npm start            # prod
```

### Variables d'environnement (backend/.env)

| Variable | Rôle |
|---|---|
| `HOST` | Hôte d'écoute (`0.0.0.0`) |
| `PORT` | Port d'écoute (`3000`) |
| `NODE_ENV` | `development` \| `test` \| `production` |
| `DATABASE_URL` | Chaîne de connexion PostgreSQL |
| `CORS_ORIGIN` | Origines autorisées (`*` en dev) |

## API (Phase 1)

| Méthode | Route | Réponse |
|---|---|---|
| GET | `/health` | `{ "status": "ok" }` |
| GET | `/countries` | Liste statique de pays (démo) |

## Tests

```powershell
# Backend
cd backend
npm test            # Vitest (health, countries)
npm run typecheck   # TypeScript strict

# Flutter
cd app
flutter analyze
flutter test

# Android natif (tests unitaires Kotlin)
cd app/android
gradlew testDebugUnitTest
```

## Documentation

Voir [docs/architecture.md](docs/architecture.md) : architecture Flutter, couche
VPN, backend, multi-provider, sécurité.
