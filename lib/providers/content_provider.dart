import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../services/github_service.dart';
import '../services/sync_service.dart';
import '../services/connectivity_service.dart';

class ContentProvider extends ChangeNotifier {
  final GithubService githubService;
  final SyncService syncService;
  final ConnectivityService connectivityService;

  ContentProvider({
    required this.githubService,
    required this.syncService,
    required this.connectivityService,
  });

  List<Song> _items = [];
  List<Song> _filteredItems = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedCategory;
  bool _favoritesOnly = false;
  bool _isOffline = false;

  // Favoris
  final Set<String> _favoriteIds = {};
  double _fontSize = 12.0;

  // Stats offline
  DateTime? _lastSync;
  int _cacheSizeBytes = 0;

  List<Song> get items => _filteredItems;
  List<Song> get allItems => _items;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  bool get favoritesOnly => _favoritesOnly;
  double get fontSize => _fontSize;
  Set<String> get favoriteIds => _favoriteIds;
  bool get isOffline => _isOffline;
  DateTime? get lastSync => _lastSync;
  int get cacheSizeBytes => _cacheSizeBytes;

  List<String> get categories {
    final cats = _items.map((e) => e.category).toSet().toList();
    cats.sort();
    return cats;
  }

  int get totalCount => _items.length;

  String _songKey(Song s) => '${s.id}-${s.title}';

  // Charge d'abord le bundle local (instantané, 100% offline), puis sync en arrière-plan
  Future<void> loadContent({bool forceRefresh = false, bool backgroundSync = true}) async {
    // 1. Charger préférences locales
    await _loadFavorites();
    await _loadFontSize();

    // 2. Essayer d'abord le bundle local (toujours disponible, pas besoin de réseau)
    if (!forceRefresh) {
      final bundled = await _loadBundledSongs();
      if (bundled.isNotEmpty) {
        _items = bundled;
        _applyFilters();
        _isLoading = false;
        _error = null;
        _isOffline = true; // Mode offline par défaut avec le bundle
        notifyListeners();

        // Pas de métadonnées de sync pour le bundle
        _lastSync = null;
        _cacheSizeBytes = 0;

        // Puis sync en arrière-plan si activé (pour mettre à jour depuis GitHub)
        if (backgroundSync) {
          _backgroundSync();
        }
        return;
      }
    }

    // 3. Si forceRefresh ou bundle vide, utiliser le nouveau service de synchronisation
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Utiliser le nouveau service de sync Offline-First
      _items = await syncService.syncSongs(forceRefresh: forceRefresh);
      _applyFilters();
      _error = null;
      
      // Mettre à jour les métadonnées
      _lastSync = await syncService.getLastSyncDate();
      _cacheSizeBytes = await syncService.getCacheSize();
      
      // Mettre à jour le statut offline
      _isOffline = connectivityService.syncStatus == SyncStatus.offline;
      
    } catch (e) {
      _error = 'Impossible de charger les chants. Vérifiez votre connexion internet.';
      _items = [];
      _filteredItems = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sync en arrière-plan non bloquant
  Future<void> _backgroundSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();
    
    try {
      // Utiliser le nouveau service de synchronisation
      final fresh = await syncService.syncSongs(forceRefresh: true);
      
      if (fresh.isNotEmpty) {
        // Vérifier si les données ont changé
        final newJson = jsonEncode(fresh.map((s) => s.toJson()).toList());
        final hasChanged = await syncService.hasDataChanged(newJson);
        
        if (hasChanged || fresh.length != _items.length) {
          // Données changées - remplacer les données locales
          _items = fresh;
          _applyFilters();
          _lastSync = await syncService.getLastSyncDate();
          _cacheSizeBytes = await syncService.getCacheSize();
        } else {
          // Mêmes données, juste mettre à jour la date de sync
          _lastSync = DateTime.now();
        }
      }
      
      _isOffline = connectivityService.syncStatus == SyncStatus.offline;
      _error = null;
    } catch (e) {
      _isOffline = true;
      // Garder le cache actuel - ne pas remplacer
      _error = null;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> syncCheck() async {
    // Vérifie si le repo a été mis à jour
    try {
      final lastCommit = await githubService.getLastCommitDate();
      final lastSync = await syncService.getLastSyncDate();
      if (lastCommit != null && lastSync != null && lastCommit.isAfter(lastSync)) {
        await loadContent(forceRefresh: true, backgroundSync: false);
        return;
      }
    } catch (_) {}
    // sinon force reload
    await loadContent(forceRefresh: true, backgroundSync: false);
  }

  // Téléchargement manuel hors-ligne
  Future<bool> downloadForOffline() async {
    _isSyncing = true;
    notifyListeners();
    try {
      final fresh = await githubService.fetchSongs();
      if (fresh.isNotEmpty) {
        _items = fresh;
        _applyFilters();
        await syncService.saveSongsAtomically(fresh, jsonEncode(fresh.map((s) => s.toJson()).toList()));
        _lastSync = DateTime.now();
        _cacheSizeBytes = await syncService.getCacheSize();
        _isOffline = false;
        connectivityService.markSynced();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> clearOfflineCache() async {
    await syncService.clearCache();
    _lastSync = null;
    _cacheSizeBytes = 0;
    connectivityService.setSyncStatus(SyncStatus.offline);
    notifyListeners();
  }

  // Recherche – améliorée
  void search(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    notifyListeners();
  }

  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void toggleFavoritesOnly() {
    _favoritesOnly = !_favoritesOnly;
    _applyFilters();
    notifyListeners();
  }

  void setFavoritesOnly(bool v) {
    _favoritesOnly = v;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _favoritesOnly = false;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    var result = _items;

    if (_favoritesOnly) {
      result = result.where((s) => _favoriteIds.contains(_songKey(s))).toList();
    }

    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      result = result.where((item) => item.category.toLowerCase() == _selectedCategory!.toLowerCase()).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      // recherche avancée : split mots
      final terms = q.split(RegExp(r'\s+')).where((t) => t.length > 1).toList();
      if (terms.isEmpty) {
        // recherche simple
        result = result.where((item) {
          final haystack = '${item.title} ${item.lyrics} ${item.author} ${item.category}'.toLowerCase();
          return haystack.contains(q);
        }).toList();
      } else {
        // tous les termes doivent matcher
        result = result.where((item) {
          final haystack = '${item.title} ${item.lyrics} ${item.author} ${item.category}'.toLowerCase();
          return terms.every((term) => haystack.contains(term));
        }).toList();
      }
    }

    // tri : favoris d'abord si recherche active ? non, alphabétique
    result.sort((a, b) => a.title.compareTo(b.title));

    _filteredItems = result;
  }

  // Favoris
  bool isFavorite(Song song) => _favoriteIds.contains(_songKey(song));

  Future<void> toggleFavorite(Song song) async {
    final key = _songKey(song);
    if (_favoriteIds.contains(key)) {
      _favoriteIds.remove(key);
    } else {
      _favoriteIds.add(key);
    }
    await _saveFavorites();
    if (_favoritesOnly) _applyFilters();
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorites') ?? [];
    _favoriteIds
      ..clear()
      ..addAll(list);
    // charge aussi lastSync
    _lastSync = await syncService.getLastSyncDate();
    _cacheSizeBytes = await syncService.getCacheSize();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favoriteIds.toList());
  }

  // Font size
  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('font_size') ?? 12.0;
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(12.0, 30.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', _fontSize);
    notifyListeners();
  }

  void increaseFont() => setFontSize(_fontSize + 2);
  void decreaseFont() => setFontSize((_fontSize - 2).clamp(12.0, 30.0));

  Song? getById(int id) {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // Charge le JSON embarqué dans assets/data/songs.json – 100% offline first run
  Future<List<Song>> _loadBundledSongs() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/songs.json');
      final data = jsonDecode(jsonString);
      if (data is Map<String, dynamic>) {
        // format { "songs": [...] }
        for (var key in ['songs', 'items', 'data', 'chants']) {
          if (data[key] is List) {
            return (data[key] as List)
                .map((e) => Song.fromJson(e as Map<String, dynamic>, sourceFile: 'bundled'))
                .toList();
          }
        }
      } else if (data is List) {
        return data.map((e) => Song.fromJson(e as Map<String, dynamic>, sourceFile: 'bundled')).toList();
      }
    } catch (_) {}
    return [];
  }

  // Stats
  String get cacheSizeText {
    if (_cacheSizeBytes < 1024) return '${_cacheSizeBytes} o';
    if (_cacheSizeBytes < 1024 * 1024) return '${(_cacheSizeBytes / 1024).toStringAsFixed(1)} Ko';
    return '${(_cacheSizeBytes / 1024 / 1024).toStringAsFixed(2)} Mo';
  }

  String get lastSyncText {
    if (_lastSync == null) return 'Jamais';
    final diff = DateTime.now().difference(_lastSync!);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }
}
