# Architecture Offline-First - Synchronisation

## Vue d'ensemble

Ce document décrit l'architecture de synchronisation **Offline-First** implémentée dans l'application Antsan'ny Fitia. Cette architecture garantit que l'application fonctionne de manière fiable même sans connexion Internet, tout en synchronisant les données dès que possible.

## Principes fondamentaux

### 1. **Offline-First**
- L'application fonctionne **toujours** avec les données locales
- Le mode hors-ligne est le comportement par défaut
- La synchronisation est une optimisation, pas une nécessité

### 2. **Aucune perte de données**
- Les données locales ne sont **jamais** remplacées par des données incomplètes
- En cas d'échec de synchronisation, le dernier snapshot valide est conservé
- La sauvegarde est **atomique** : on écrit d'abord, puis on confirme

### 3. **États de synchronisation**

L'application peut être dans un des 4 états suivants :

| État | Description | Icône | Couleur |
|------|-------------|-------|---------|
| `synced` | Données synchronisées avec succès | ☁️✓ | Vert |
| `syncing` | Synchronisation en cours | 🔄 | Orange |
| `offline` | Pas de connexion Internet | ☁️✗ | Gris |
| `error` | Erreur lors de la synchronisation | ⚠️ | Rouge |

## Architecture des services

### 1. **ConnectivityService** (`lib/services/connectivity_service.dart`)

**Responsabilité** : Détecter l'état de la connexion réseau et gérer les états de synchronisation.

**Fonctionnalités** :
- Surveillance en temps réel de la connectivité via `connectivity_plus`
- Gestion des états : `synced`, `syncing`, `offline`, `error`
- Stockage du timestamp `lastSyncedAt`
- Notification automatique des changements d'état

**Utilisation** :
```dart
final connectivityService = context.read<ConnectivityService>();
final isOnline = connectivityService.isOnline;
final syncStatus = connectivityService.syncStatus;
final lastSync = connectivityService.lastSyncedAt;
```

### 2. **SyncService** (`lib/services/sync_service.dart`)

**Responsabilité** : Gérer la synchronisation des données avec le serveur GitHub.

**Fonctionnalités** :
- Synchronisation **Offline-First** avec sauvegarde atomique
- Double stockage : SharedPreferences (rapide) + Fichier (persistant)
- Détection de changements par hash
- Fallback automatique vers le bundle embarqué

**Méthodes principales** :

#### `syncSongs({bool forceRefresh = false})`
Synchronise les chansons depuis le serveur.

**Comportement** :
1. **Vérifie la connectivité**
   - Si hors-ligne → retourne le cache local
   - Si en ligne → continue la synchronisation

2. **Tentative de synchronisation**
   - Récupère les données depuis GitHub
   - Vérifie si les données ont changé (hash)
   - Si identiques → marque comme `synced` sans écrire
   - Si différentes → sauvegarde atomique

3. **En cas d'échec**
   - Marque l'état comme `error`
   - Retourne le cache local (dernier snapshot valide)
   - **Ne vide jamais** le cache local

#### `saveSongsAtomically(List<Song> songs, String jsonString)`
Sauvegarde atomique des chansons.

**Processus** :
1. Écriture dans SharedPreferences (rapide)
2. Écriture dans un fichier temporaire
3. Renommage atomique du fichier temporaire vers le fichier final

**Garantie** : Si l'écriture fichier échoue, SharedPreferences a déjà sauvegardé les données. Le cache reste cohérent.

#### `loadCachedSongs()`
Charge les chansons depuis le cache local.

**Ordre de priorité** :
1. SharedPreferences (plus rapide)
2. Fichier local (fallback)
3. Bundle embarqué (dernier recours)

### 3. **ContentProvider** (`lib/providers/content_provider.dart`)

**Responsabilité** : Fournir les données à l'interface utilisateur et gérer l'état de l'application.

**Intégration avec SyncService** :
- Utilise `syncService.syncSongs()` pour charger les données
- Écoute les changements de `connectivityService.syncStatus`
- Met à jour l'interface en fonction de l'état de synchronisation

**Flux de chargement** :

```
1. Charger les préférences (favoris, taille police)
2. Essayer le bundle local (instantané, 100% offline)
   └─ Si trouvé → afficher + sync en arrière-plan
3. Sinon → utiliser SyncService.syncSongs()
   ├─ Si hors-ligne → retourne cache local
   ├─ Si en ligne → tente synchronisation
   │  ├─ Succès → remplace cache local
   │  └─ Échec → conserve cache local
   └─ Met à jour les métadonnées (lastSync, cacheSize)
```

## Flux de synchronisation

### Première synchronisation

```
Serveur → Données → Sauvegarde locale → lastSyncedAt = maintenant
```

### Nouvelle synchronisation réussie

```
Serveur → Nouvelles données → Vérification hash
  ├─ Données identiques → lastSyncedAt = maintenant
  └─ Données différentes → Remplacement du snapshot local
```

### Mode Offline

```
Cache local (dernier snapshot valide) → Application
```

### Synchronisation échouée

```
Serveur ❌ → Conserver le dernier snapshot local valide
```

## Gestion des états

### Transitions d'états

```
                    ┌─────────────┐
                    │   offline   │
                    └──────┬──────┘
                           │
                    [connexion détectée]
                           │
                           ▼
                    ┌─────────────┐
                    │   syncing   │
                    └──────┬──────┘>
                           │
                    ┌──────┴──────┐
                    │             │
              [succès]         [échec]
                    │             │
                    ▼             ▼
            ┌───────────┐   ┌───────────┐
            │  synced   │   │   error   │
            └─────┬─────┘   └─────┬─────┘
                  │               │
                  │               │ [nouvelle tentative]
                  │               │
                  └───────────────┘
                         │
                   [perte connexion]
                         │
                         ▼
                   ┌───────────┐
                   │  offline  │
                   └───────────┘
```

### Détection automatique

La détection de connexion est automatique grâce à `connectivity_plus` :

```dart
_connectivity.onConnectivityChanged.listen((result) {
  _updateConnectionStatus(result);
});
```

Lorsque la connexion est rétablie, l'application reste en mode `offline` jusqu'à la prochaine synchronisation explicite.

## Stockage local

### Double sauvegarde

Pour garantir la persistance et la performance :

1. **SharedPreferences** (rapide)
   - Accès ultra-rapide
   - Utilisé pour les lectures fréquentes
   - Taille limitée (~5 MB)

2. **Fichier JSON** (persistant)
   - Écriture atomique (fichier temporaire + renommage)
   - Sauvegarde robuste
   - Peut gérer des fichiers volumineux

### Structure des données

**SharedPreferences** :
- `cached_songs_json` : JSON des chansons
- `last_sync` : Date de dernière synchronisation (ISO 8601)
- `songs_count` : Nombre de chansons
- `songs_data_hash` : Hash des données pour détecter les changements
- `sync_status` : État de synchronisation

**Fichier** :
- `songs_cache.json` : Copie de sauvegarde

## Interface utilisateur

### Widget SyncStatusWidget

Un widget prêt à l'emploi pour afficher le statut de synchronisation :

```dart
SyncStatusWidget()
```

**Affichage** :
- 🟢 **Synchronisé** : "Synchronisé • il y a 5 min"
- 🟠 **Synchronisation...** : "Synchronisation..." + spinner
- ⚫ **Hors ligne** : "Hors ligne"
- 🔴 **Erreur** : "Erreur de synchronisation"

## Comportements attendus

### ✅ Cas nominaux

1. **Premier lancement avec Internet**
   - Bundle local affiché immédiatement
   - Synchronisation en arrière-plan
   - Cache mis à jour avec les données du serveur

2. **Mode Offline**
   - Application fonctionne normalement
   - Dernières données synchronisées affichées
   - Aucune erreur affichée à l'utilisateur

3. **Retour en ligne**
   - Synchronisation automatique en arrière-plan
   - Données mises à jour si nécessaire
   - Interface notifiée du changement

### ⚠️ Cas d'erreur

1. **Synchronisation échouée**
   - Cache local conservé intact
   - État passe à `error`
   - Utilisateur peut continuer à utiliser l'application

2. **Serveur retourne des données vides**
   - Cache local conservé
   - État passe à `error`
   - Message d'erreur dans les logs

3. **Fichier de cache corrompu**
   - Fallback vers SharedPreferences
   - Si corrompu → fallback vers bundle
   - Aucune perte de données

## Tests de validation

### Test 1 : Mode Offline
1. Activer le mode avion
2. Lancer l'application
3. ✅ Les données s'affichent (bundle ou cache)
4. ✅ Aucune erreur affichée
5. ✅ État = `offline`

### Test 2 : Première synchronisation
1. Désactiver le mode avion
2. Lancer l'application (première fois)
3. ✅ Bundle affiché immédiatement
4. ✅ Synchronisation en arrière-plan
5. ✅ Données mises à jour
6. ✅ État = `synced`
7. ✅ `lastSyncedAt` mis à jour

### Test 3 : Synchronisation échouée
1. Simuler une erreur réseau (proxy, firewall)
2. Tenter une synchronisation
3. ✅ Cache local conservé
4. ✅ État = `error`
5. ✅ Données toujours disponibles

### Test 4 : Online → Offline → Online
1. Lancer l'application en ligne
2. ✅ Synchronisation réussie
3. Activer le mode avion
4. ✅ Application fonctionne hors-ligne
5. Désactiver le mode avion
6. ✅ Nouvelle synchronisation
7. ✅ Données mises à jour
8. ✅ Aucune perte de données

## Bonnes pratiques

### ✅ À faire

1. **Toujours utiliser SyncService** pour charger les données
2. **Vérifier l'état de synchronisation** avant les opérations critiques
3. **Gérer les cas d'erreur** avec des fallbacks
4. **Tester en mode hors-ligne** régulièrement

### ❌ À éviter

1. **Ne jamais vider le cache** sans confirmation utilisateur
2. **Ne jamais remplacer** les données locales par des données incomplètes
3. **Ne jamais supposer** que le réseau est disponible
4. **Ne jamais ignorer** les erreurs de synchronisation

## Maintenance

### Vider le cache

```dart
await syncService.clearCache();
```

### Forcer une synchronisation

```dart
await contentProvider.loadContent(forceRefresh: true);
```

### Vérifier le statut

```dart
final status = await syncService.getSyncStatus();
final lastSync = await syncService.getLastSyncDate();
final cacheSize = await syncService.getCacheSize();
```

## Dépannage

### Problème : L'application reste en mode offline

**Solution** :
1. Vérifier les permissions réseau (Android/iOS)
2. Vérifier que `connectivity_plus` est correctement configuré
3. Tester avec `connectivityService.checkConnectivity()`

### Problème : Les données ne se synchronisent pas

**Solution** :
1. Vérifier l'URL du repository GitHub
2. Vérifier les tokens d'authentification (si nécessaire)
3. Consulter les logs d'erreur dans `connectivityService.errorMessage`

### Problème : Le cache est corrompu

**Solution** :
1. L'application utilise automatiquement le fallback
2. Pour réinitialiser : `await syncService.clearCache()`
3. Relancer l'application

## Conclusion

Cette architecture **Offline-First** garantit que :

✅ L'application fonctionne **toujours**, même sans Internet  
✅ Les données sont **jamais perdues** lors des synchronisations  
✅ L'utilisateur a toujours accès à la **dernière version valide**  
✅ La synchronisation est **transparente** et **automatique**  
✅ Les états sont **clairs** et **visibles**  

L'utilisateur peut ainsi consulter et utiliser les chants de la chorale **sans interruption**, que ce soit à l'église, chez lui, ou en déplacement.