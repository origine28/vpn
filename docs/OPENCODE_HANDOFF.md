# OPENCODE HANDOFF — VPN PROJECT

> Ce document permet à une session OpenCode de reprendre le projet VPN sans historique de conversation.
> Date de dernière mise à jour : 2026-08-20

---

## Contexte

Application VPN mobile Android + Flutter Web. L'utilisateur choisit un pays, le backend détermine le meilleur serveur, et le client établit la connexion WireGuard. Flutter Web est en simulation uniquement.

Architecture : **Flutter (UI) + Kotlin natif (VPN Android) + Backend (Fastify/Prisma/PostgreSQL)**.

---

## Décisions techniques

| Domaine | Choix | Raison |
|---|---|---|
| UI | Flutter + Riverpod | State management réactif, multi-plateforme |
| Routing | GoRouter | Déclaratif, type-safe |
| HTTP | Dio | Interceptors, cancel tokens |
| Interop Flutter↔Kotlin | Pigeon 27 | Messages typés, codegen |
| VPN Android | VpnService + GoBackend | API officielle WireGuard |
| Crypto | com.wireguard.crypto.KeyPair | Curve25519 officielle, pas de code custom |
| Backend | Fastify + TypeScript strict | Performance, fiabilité |
| ORM | Prisma 7 + PostgreSQL | Type-safe, migrations |
| Tests backend | Vitest | Rapide, ESM-native |
| Tests Flutter | flutter_test | Intégré, widget tests |

---

## Phases terminées

- **Phase 0** : Audit et architecture
- **Phase 1** : Bootstrap (Flutter, backend, Git, docs)
- **Phase 2** : Pigeon, AndroidVpnController, VpnService, événements
- **Phase 3** : API pays/serveurs, sélection, config (implémentée, tests unitaires OK)
- **Phase 4A-C** : WireGuard (implémenté : KeyPair, GoBackend, Backend routes, Flutter connectWithWireGuard)

---

## Phase actuelle

Phase 4 implémentée mais **non testée E2E sur device**. Le premier commit Git doit être créé et poussé vers GitHub.

---

## Fichiers importants

| Fichier | Rôle |
|---|---|
| `app/pigeon/vpn_messages.dart` | Définition du contrat Flutter↔Kotlin |
| `app/lib/platform/vpn/android_vpn_controller.dart` | Contrôleur VPN Android (Pigeon) |
| `app/lib/features/vpn/domain/vpn_controller.dart` | Interface abstraite VpnController |
| `app/android/.../vpn/WireGuardKeyGenerator.kt` | Génération clés Curve25519 |
| `app/android/.../vpn/WireGuardTunnelManager.kt` | Gestion tunnel GoBackend |
| `app/android/.../vpn/MainVpnService.kt` | Service VPN Android |
| `backend/src/routes/vpn.ts` | Endpoint connexion/déconnexion |
| `backend/src/services/vpn-orchestrator.ts` | Sélection serveur |
| `backend/prisma/schema.prisma` | Modèles DB |
| `backend/.env.wireguard.example` | Configuration WireGuard serveur |
| `docs/architecture.md` | Architecture complète |
| `docs/PROJECT_STATUS.md` | État du projet |

---

## Commandes de test

```powershell
# Backend
cd backend
npm test                # 30 tests
npm run typecheck       # TypeScript strict

# Flutter
cd app
flutter analyze         # No issues found
flutter test            # 36 tests

# Build
cd app
flutter build web       # Simulation Web
flutter build apk --debug  # APK debug
```

---

## Problèmes connus

1. `.env.wireguard.example` doit être tracké (pattern `.gitignore` corrigé)
2. `adb` pas dans PATH — impossible de tester sur device
3. `VpnMessages.kt` généré contient `toString()` avec `clientPrivateKey` (risque si logué)
4. `isValidPrivateKey`/`isValidPublicKey` sont identiques dans `WireGuardKeyGenerator.kt`
5. WireGuard en mode SIMULATION (pas de serveur réel)
6. `VpnConnection` table DB non utilisée au runtime (connexions en mémoire)
7. Application ID temporaire `com.vpnproj.vpnapp`
8. Aucun remote GitHub configuré

---

## Prochaine tâche

Créer le premier commit Git et pousser vers GitHub. Ensuite : configurer un serveur WireGuard réel et tester E2E sur un appareil Android.

---

## Tâches explicitement interdites pour le moment

- Commencer Phase 5
- Intégrer un fournisseur VPN commercial
- Modifier l'architecture existante
- Réécrire WireGuard
- Supprimer des tests
- Faire git reset --hard ou git clean -fd
- Exposer des secrets
- Publier le repository publiquement

---

## Procédure de reprise

1. Lire ce document
2. Lire `docs/PROJECT_STATUS.md`
3. Vérifier `git status` et `git log`
4. Exécuter `npm test` (backend) et `flutter test` (app)
5. Consulter la section NEXT ACTION ci-dessous

---

## NEXT ACTION

**Créer le premier commit Git du projet et pousser vers GitHub.**

```powershell
cd projets/mobile/vpn
git add .
git status
git commit -m "feat: VPN project — Flutter + Kotlin + WireGuard + backend"
# Puis configurer le remote et push (voir section Git du rapport final)
```
