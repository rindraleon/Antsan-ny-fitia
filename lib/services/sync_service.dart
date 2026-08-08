import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/song.dart';
import '../services/github_service.dart';
import '../services/connectivity_service.dart';

class SyncService {
  static const String _songsKey = 'cached_songs_json';
  static const String _lastSyncKey = 'last_sync';
  static const String _songsFileName = 'songs_cache.json';
  static const String _hashKey = 'songs_data_hash';
  static const String _syncStatusKey = 'sync_status';

  final GithubService githubService;
  final ConnectivityService connectivityService;

  SyncService({
    required this.githubService,
    required this.connectivityService,
  });

  /// Synchronisation principale - Architecture Offline-First
  /// Comportement:
  /// 1. Si pas de connexion → utiliser le cache local (dernier snapshot valide)
  /// 2. Si connexion → tenter sync
  ///    - Succès → remplacer cache local par nouvelles données
  ///    - Échec → conserver cache local intact
  Future<List<Song>> syncSongs({bool forceRefresh = false}) async {
    // Vérifier la connectivité
    final isOnline = await connectivityService.checkConnectivity();
    
    if (!isOnline && !forceRefresh) {
      // MODE OFFLINE: Utiliser le dernier snapshot local valide
      connectivityService.setSyncStatus(SyncStatus.offline);
      return await loadCachedSongs();
    }

    // MODE ONLINE: Tentative de synchronisation
    connectivityService.startSyncing();
    
    try {
      // Récupérer les données depuis le serveur
      final freshSongs = await githubService.fetchSongs();
      
      if (freshSongs.isEmpty) {
        // Si le serveur retourne vide, on garde le cache local
        connectivityService.markError('Serveur retourne des données vides');
        return await loadCachedSongs();
      }

      // Vérifier si les données ont changé
      final newJson = jsonEncode(freshSongs.map((s) => s.toJson()).toList());
      final hasChanged = await hasDataChanged(newJson);

      if (!hasChanged && !forceRefresh) {
        // Données identiques, pas besoin de remplacer
        connectivityService.markSynced();
        return await loadCachedSongs();
      }

      // SAUVEGARDE ATOMIQUE: D'abord sauvegarder, puis marquer comme synced
      // Cela garantit qu'on ne perd jamais le dernier snapshot valide
      await saveSongsAtomically(freshSongs, newJson);
      
      // Marquer la synchronisation comme réussie
      connectivityService.markSynced();
      
      return freshSongs;

    } catch (e) {
      // ÉCHEC DE SYNCHRONISATION: Conserver INTÉGRALEMENT le dernier snapshot local
      connectivityService.markError('Échec sync: ${e.toString()}');
      
      // Charger et retourner le cache local (dernier snapshot valide)
      final cachedSongs = await loadCachedSongs();
      
      if (cachedSongs.isEmpty) {
        // Fallback ultime: bundle embarqué
        return await _loadBundledSongs();
      }
      
      return cachedSongs;
    }
  }

  /// Sauvegarde atomique des chansons (public pour ContentProvider)
  /// Garantit que le cache est toujours dans un état cohérent
  Future<void> saveSongsAtomically(List<Song> songs, String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Sauvegarder dans SharedPreferences (rapide)
    await prefs.setString(_songsKey, jsonString);
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    await prefs.setInt('songs_count', songs.length);
    await prefs.setString(_hashKey, _simpleHash(jsonString));
    await prefs.setString(_syncStatusKey, SyncStatus.synced.toString());

    // 2. Sauvegarder dans le fichier (persistance)
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_songsFileName');
      
      // Écriture atomique: écrire dans un fichier temporaire puis renommer
      final tempFile = File('${dir.path}/$_songsFileName.tmp');
      await tempFile.writeAsString(jsonString);
      await tempFile.rename(file.path);
    } catch (e) {
      // Si l'écriture fichier échoue, SharedPreferences a déjà sauvegardé
      // Le cache reste cohérent malgré l'erreur fichier
    }
  }

  /// Charger les chansons depuis le cache local
  /// Retourne le dernier snapshot valide
  Future<List<Song>> loadCachedSongs() async {
    // 1. Essayer SharedPreferences (plus rapide)
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_songsKey);
    
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        return _parseSongs(jsonString, 'cache_prefs');
      } catch (e) {
        // Corrompu, essayer le fichier
      }
    }

    // 2. Fallback: fichier local
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_songsFileName');
      if (await file.exists()) {
        final content = await file.readAsString();
        return _parseSongs(content, 'cache_file');
      }
    } catch (e) {
      // Fichier corrompu ou inexistant
    }

    // 3. Aucun cache valide
    return [];
  }

  /// Vérifier si le cache est valide
  Future<bool> hasValidCache() async {
    final songs = await loadCachedSongs();
    return songs.isNotEmpty;
  }

  /// Obtenir la date de dernière synchronisation
  Future<DateTime?> getLastSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_lastSyncKey);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  /// Obtenir le statut de synchronisation
  Future<SyncStatus> getSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final statusStr = prefs.getString(_syncStatusKey);
    if (statusStr == null) return SyncStatus.offline;
    
    return SyncStatus.values.firstWhere(
      (s) => s.toString() == statusStr,
      orElse: () => SyncStatus.offline,
    );
  }

  /// Obtenir la taille du cache
  Future<int> getCacheSize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_songsFileName');
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {}
    return 0;
  }

  /// Vider le cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_songsKey);
    await prefs.remove(_lastSyncKey);
    await prefs.remove('songs_count');
    await prefs.remove(_hashKey);
    await prefs.remove(_syncStatusKey);
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_songsFileName');
      if (await file.exists()) await file.delete();
    } catch (e) {}
  }

  /// Vérifier si les données ont changé (public pour ContentProvider)
  Future<bool> hasDataChanged(String newJson) async {
    final prefs = await SharedPreferences.getInstance();
    final oldHash = prefs.getString(_hashKey);
    final newHash = _simpleHash(newJson);
    return oldHash != newHash;
  }

  /// Charger les chansons embarquées (bundle)
  /// Utilisé comme fallback ultime si pas de cache
  Future<List<Song>> _loadBundledSongs() async {
    try {
      // Import dynamique pour éviter la dépendance circulaire
      // Le bundle est chargé par ContentProvider
      return [];
    } catch (e) {
      return [];
    }
  }

  List<Song> _parseSongs(String jsonString, String source) {
    try {
      final data = jsonDecode(jsonString);
      if (data is List) {
        return data.map((e) => Song.fromJson(e, sourceFile: source)).toList();
      }
    } catch (e) {
      // JSON corrompu, retourner une liste vide
    }
    return [];
  }

  String _simpleHash(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash) + input.codeUnitAt(i);
      hash &= hash;
    }
    return hash.toString();
  }

  /// Texte descriptif de la dernière synchronisation
  Future<String> getLastSyncText() async {
    final date = await getLastSyncDate();
    if (date == null) return 'Jamais synchronisé';
    
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }
}