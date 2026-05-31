# 🕵️‍♀️ SupKonQuest — Totally Spies Edition

> Jeu de stratégie / conquête temps réel — Projet 2PROJ · SUPINFO Paris  
> Capturez des camps, produisez des unités, éliminez vos adversaires.

- **Moteur :** Godot 4.6.2
- **Plateforme :** Windows x86_64
- **Langage :** GDScript
- **Statut :** Playable ✅

---

## 🎮 Présentation

| Moteur | Godot 4.6.2 stable (GL Compatibility) |
|--------|---------------------------------------|
| Plateforme | Windows x86_64 uniquement |
| Langage | GDScript |
| Rendu | GL Compatibility / Direct3D12 |
| Physique | Jolt Physics |
| Cartes | 3 (Beverly Hills · Jungle Techno · Île Tropicale) |
| Unités | 10 types (7 terrestres + 3 navales) |
| Langues | Français · Anglais · Espagnol |

### Modes de jeu

- **vs IA** — 3 niveaux : Facile / Moyen / Difficile
- **Multijoueur en ligne** — relay WebSocket hébergé sur Render 1vs1 - 2vs2 - 3vs3

---

## 🚀 Lancer le jeu

### Exécutable (recommandé)
SupSpy/SupSpy.exe

### Développement (Godot 4.6.2 stable)

1. Ouvrir `2PROJ_SupSpy/` dans l'éditeur Godot
2. `F5` pour lancer

---

## 🗂️ Structure du projet

```
2PROJ_Hanitea_Asma_Paola_Dalila/
├── 2PROJ_SupSpy/               # Projet source Godot
├── SupSpy/                     # Jeu exporté (SupSpy.exe)
├── Documentation_technique/
└── Manual_user/
```

### Projet Godot (`2PROJ_SupSpy/`)

```
2PROJ_SupSpy/
├── project.godot               # Config moteur + autoloads
├── export_presets.cfg
├── assets/
│   ├── sprites/
│   ├── tilesets/
│   ├── units/
│   └── video/
├── scenes/
│   ├── maps/
│   ├── online/                 # Login, Register, OnlineMenu, SalleAttente…
│   ├── ui/
│   ├── camp_base.tscn
│   └── main.tscn               # Scène principale (boucle de jeu)
└── scripts/
    ├── Main.gd
    ├── Camp.gd
    ├── Player.gd · Tourelle.gd · Combat.gd
    ├── SelectionManager.gd · NavBaker.gd · RegionDefs.gd
    ├── ai/                     # IController + AIEasy / AIMedium / AIHard
    ├── ships/                  # Unités navales
    ├── units/                  # Unités terrestres
    ├── autoloads/              # Singletons globaux
    ├── online/                 # Logique du funnel en ligne
    └── ui/                     # HUD, menus, minimap, leaderboard, Lang
```
---

## 🧩 Architecture

### Autoloads (singletons globaux)

| Autoload | Rôle |
|----------|------|
| `GameConfig` | Source de vérité de la session (mode, map, diff, joueurs, token, is_host, elo…) |
| `GameManager` | Tableau des joueurs, revenus, bonus de région, détection de victoire |
| `NetworkManager` | Connexion multijoueur via relay WebSocket. Réveille les serveurs Render au démarrage |
| `Matchmaker` | Comptes (register / login / stats / Elo / leaderboard) + registre local en repli |
| `RoomManager` | Registre des rooms côté hôte, assignation des `join_order` |
| `SceneLoader` | Transitions de scènes |

**Autoloads de données statiques (aucun état) :**

| Autoload | Rôle |
|----------|------|
| `UnitDefs` | Stats et prix des 10 types d'unités |
| `MapDefs` | Camps, régions, adjacences, forêts des cartes |
| `Lang` | i18n fr / en / es |
| `Combat` | `resolve(src, tgt)` sans état |
| `Sound` | Lecture audio |

### Boucle de jeu (`Main.gd`)

- Lit `GameConfig.mode` (`"ai"` / `"multi"` / `""` pour le local)
- Instancie les `Camp` depuis `MapDefs.MAPS`
- Gère les entrées dans `_unhandled_input()`
- Résout les attaques via `Combat.resolve(src, tgt)`
- **Multi** : attaques/recrutements en RPC, hôte diffuse l'état toutes les 0,5 s
- **IA** : `_run_ai_tick()` toutes les 3 s

### Modèle d'autorité multijoueur

- L'hôte (`GameConfig.is_host = true`) est toujours la référence
- Seul l'hôte distribue les revenus et diffuse l'état autoritatif
- Les clients envoient leurs actions en RPC
- `local_player_id` dérive de `join_order + 1`

### Funnel des scènes en ligne
Login → (Register) → OnlineMenu → NomRoom (hôte) / ListeRooms (client)
→ ChoixMode → ChoixFormat → ChoixDiff → ChoixMap → SalleAttente → Main

---

## ☁️ Infrastructure en ligne

Deux services Node.js + une base PostgreSQL, hébergés sur **Render**.  
Les services peuvent être en cold-start ; le client les réveille au démarrage et UptimeRobot les ping en continu.

### 1. Relay WebSocket (jeu)

| | |
|-|-|
| Rôle | Relay multijoueur — distribue un `peer_id` à chaque connexion |
| URL | `wss://sup-kon-quest-server.onrender.com` |
| Healthcheck | `https://sup-kon-quest-server.onrender.com/ping` |
| Réf. client | `NetworkManager.RELAY_URL` |
| GitHub | [sup-kon-quest-server](https://github.com/crsDraxx/sup-kon-quest-server) |

### 2. Matchmaker (comptes & rooms)

| | |
|-|-|
| Rôle | Register / login / JWT / Elo (K=32) / leaderboard / profil |
| URL | `wss://sup-kon-quest-matchmaker.onrender.com` |
| Réf. client | `Matchmaker.SERVER_URL` |
| GitHub | [sup-kon-quest-matchmaker](https://github.com/crsDraxx/sup-kon-quest-matchmaker) |
| Contrat d'API | `SERVER_API.md` |

### 3. PostgreSQL (Render)

- Instance : `dpg-d864qst7vvec73epvei0-a`
- Tables : `users` (username, password haché, pseudo, wins, losses, elo)
- Auth : JWT signés côté serveur, stockés dans `GameConfig.token`

### Robustesse

Chaque fonctionnalité en ligne dispose d'un timeout + repli hors-ligne (`NetworkManager.CONNECT_TIMEOUT = 20 s`). Si un serveur ne répond pas, le jeu reste jouable en local.

---

## ⚔️ Unités & cartes

### 10 types d'unités (`UnitDefs.TYPES`)

| Catégorie | Unités |
|-----------|--------|
| Terrestres | `infantry` · `range` · `heavy` · `anti_armor` · `mortar` · `support` · `healer` |
| Navales (ports uniquement) | `spy_yacht` · `woohp_cruiser` · `shadow_vessel` |

Chaque unité possède : `hp`, `damage`, `range`, `speed`, `price`, `build_time`.

### 3 cartes jouables

| ID | Nom | Personnage |
|----|-----|------------|
| `beverly` | Beverly Hills | Clover |
| `jungle` | Jungle Techno | Sam |
| `tropical` | Île Tropicale | Alex |

---

## 👩‍💻 Équipe

Projet 2PROJ — SUPINFO Paris · thème *Totally Spies*

**Hanitea · Asma · Paola · Dalila**
