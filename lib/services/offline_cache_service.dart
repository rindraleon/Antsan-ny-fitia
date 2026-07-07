import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';

class OfflineCacheService {
  static const String _songsKey = 'cached_songs_json';
  static const String _lastSyncKey = 'last_sync';
  static const String _songsFileName = 'songs_cache.json';
  static const String _hashKey = 'songs_data_hash';
  static const String _autoSyncKey = 'auto_sync_enabled';
  static const String _wifiOnlyKey = 'sync_wifi_only';

  // Sauvegarde en SharedPreferences (rapide) + fichier (robuste)
  static Future<void> saveSongs(List<Song> songs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = songs.map((s) => s.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    
    // 1. SharedPreferences (accès ultra rapide)
    await prefs.setString(_songsKey, jsonString);
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    await prefs.setInt('songs_count', songs.length);
    await prefs.setString(_hashKey, _simpleHash(jsonString));

    // 2. Fichier local (sauvegarde persistante)
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_songsFileName');
      await file.writeAsString(jsonString);
    } catch (_) {}
  }

  static Future<List<Song>> loadCachedSongs() async {
    // Essaie SharedPreferences d'abord (plus rapide)
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_songsKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        return _parseSongs(jsonString, 'cache_prefs');
      } catch (_) {}
    }

    // Fallback fichier
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_songsFileName');
      if (await file.exists()) {
        final content = await file.readAsString();
        return _parseSongs(content, 'cache_file');
      }
    } catch (_) {}

    return [];
  }

  static List<Song> _parseSongs(String jsonString, String source) {
    final data = jsonDecode(jsonString);
    if (data is List) {
      return data.map((e) => Song.fromJson(e, sourceFile: source)).toList();
    }
    return [];
  }

  static Future<DateTime?> getLastSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_lastSyncKey);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  static Future<String> getLastSyncText() async {
    final date = await getLastSyncDate();
    if (date == null) return 'Jamais synchronisé';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }

  static Future<int> getCacheSize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_songsFileName');
      if (await file.exists()) {
        return await file.length();
      }
    } catch (_) {}
    return 0;
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_songsKey);
    await prefs.remove(_lastSyncKey);
    await prefs.remove('songs_count');
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_songsFileName');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  static Future<bool> hasValidCache() async {
    final songs = await loadCachedSongs();
    return songs.isNotEmpty;
  }

  // Paramètres sync
  static Future<bool> isAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSyncKey) ?? true;
  }

  static Future<void> setAutoSync(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, enabled);
  }

  static Future<bool> isWifiOnly() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wifiOnlyKey) ?? false;
  }

  static Future<void> setWifiOnly(bool wifiOnly) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wifiOnlyKey, wifiOnly);
  }

  static String _simpleHash(String input) {
    // hash simple pour détecter changements
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash) + input.codeUnitAt(i);
      hash &= hash;
    }
    return hash.toString();
  }

  static Future<bool> hasDataChanged(String newJson) async {
    final prefs = await SharedPreferences.getInstance();
    final oldHash = prefs.getString(_hashKey);
    final newHash = _simpleHash(newJson);
    return oldHash != newHash;
  }
}

// Service de connectivité simplifié
class ConnectivityService {
  static Future<bool> get isOnline async {
    try {
      // test simple – on utilisera connectivity_plus dans l'app
      return true;
    } catch (_) {
      return false;
    }
  }
}
