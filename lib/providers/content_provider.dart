import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../services/github_service.dart';

class ContentProvider extends ChangeNotifier {
  final GithubService githubService;

  ContentProvider({required this.githubService});

  List<Song> _items = [];
  List<Song> _filteredItems = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedCategory;
  bool _favoritesOnly = false;

  // Favoris
  final Set<String> _favoriteIds = {}; // "id-title" key
  double _fontSize = 18.0;

  List<Song> get items => _filteredItems;
  List<Song> get allItems => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  bool get favoritesOnly => _favoritesOnly;
  double get fontSize => _fontSize;
  Set<String> get favoriteIds => _favoriteIds;

  List<String> get categories {
    final cats = _items.map((e) => e.category).toSet().toList();
    cats.sort();
    return cats;
  }

  int get totalCount => _items.length;

  String _songKey(Song s) => '${s.id}-${s.title}';

  Future<void> loadContent({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // charge favoris locaux d'abord
      await _loadFavorites();
      await _loadFontSize();

      _items = await githubService.fetchSongs();
      _applyFilters();
      _error = null;

      // sauvegarde cache local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync', DateTime.now().toIso8601String());
      await prefs.setInt('songs_count', _items.length);
    } catch (e) {
      _error = e.toString();
      _items = [];
      _filteredItems = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncCheck() async {
    // Vérifie si le repo a été mis à jour
    final lastCommit = await githubService.getLastCommitDate();
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString('last_sync');
    if (lastCommit != null && lastSyncStr != null) {
      final lastSync = DateTime.tryParse(lastSyncStr);
      if (lastSync != null && lastCommit.isAfter(lastSync)) {
        // nouvelle version dispo
        await loadContent(forceRefresh: true);
        return;
      }
    }
    // sinon juste reload
    await loadContent(forceRefresh: true);
  }

  void search(String query) {
    _searchQuery = query;
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
      result = result.where((item) => item.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((item) {
        return item.title.toLowerCase().contains(q) ||
            item.lyrics.toLowerCase().contains(q) ||
            item.author.toLowerCase().contains(q) ||
            item.category.toLowerCase().contains(q);
      }).toList();
    }

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
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favoriteIds.toList());
  }

  // Font size
  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('font_size') ?? 18.0;
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(14.0, 30.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', _fontSize);
    notifyListeners();
  }

  void increaseFont() => setFontSize(_fontSize + 2);
  void decreaseFont() => setFontSize((_fontSize - 2).clamp(14.0, 30.0));

  Song? getById(int id) {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
