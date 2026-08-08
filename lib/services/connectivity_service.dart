import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum SyncStatus {
  synced,      // Données synchronisées avec succès
  syncing,     // Synchronisation en cours
  offline,     // Pas de connexion Internet
  error,       // Erreur lors de la synchronisation
}

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  
  bool _isOnline = false;
  SyncStatus _syncStatus = SyncStatus.offline;
  DateTime? _lastSyncedAt;
  String? _errorMessage;
  
  // Stream controllers pour les événements
  final ValueNotifier<SyncStatus> syncStatusNotifier = ValueNotifier<SyncStatus>(SyncStatus.offline);
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier(false);
  final ValueNotifier<DateTime?> lastSyncedAtNotifier = ValueNotifier(null);

  bool get isOnline => _isOnline;
  SyncStatus get syncStatus => _syncStatus;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get errorMessage => _errorMessage;

  ConnectivityService() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  /// Initialise l'état de connectivité au démarrage
  Future<void> _initConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(connectivityResult);
    } catch (e) {
      _isOnline = false;
      _syncStatus = SyncStatus.offline;
      _notifyListeners();
    }
  }

  /// Met à jour le statut de connexion
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    // Vérifie s'il y a une connexion active (WiFi, Ethernet, ou Mobile)
    final hasConnection = result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.mobile;

    final wasOffline = !_isOnline;
    _isOnline = hasConnection;

    if (hasConnection) {
      // Si on vient de se reconnecter, on garde le statut synced si on était synced avant
      if (wasOffline && _syncStatus == SyncStatus.offline) {
        // On reste en mode offline jusqu'à la prochaine sync
        _syncStatus = SyncStatus.offline;
      }
    } else {
      // Perte de connexion
      if (_syncStatus != SyncStatus.syncing) {
        _syncStatus = SyncStatus.offline;
      }
    }

    _notifyListeners();
  }

  /// Définit le statut de synchronisation
  void setSyncStatus(SyncStatus status, {String? error}) {
    _syncStatus = status;
    _errorMessage = error;

    if (status == SyncStatus.synced) {
      _lastSyncedAt = DateTime.now();
      lastSyncedAtNotifier.value = _lastSyncedAt;
    }

    _notifyListeners();
  }

  /// Marque la synchronisation comme réussie
  void markSynced() {
    _lastSyncedAt = DateTime.now();
    _syncStatus = SyncStatus.synced;
    _errorMessage = null;
    lastSyncedAtNotifier.value = _lastSyncedAt;
    _notifyListeners();
  }

  /// Marque le début de la synchronisation
  void startSyncing() {
    _syncStatus = SyncStatus.syncing;
    _errorMessage = null;
    _notifyListeners();
  }

  /// Marque une erreur de synchronisation
  void markError(String error) {
    _syncStatus = SyncStatus.error;
    _errorMessage = error;
    _notifyListeners();
  }

  /// Vérifie manuellement la connectivité
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(result);
      return _isOnline;
    } catch (e) {
      return false;
    }
  }

  void _notifyListeners() {
    syncStatusNotifier.value = _syncStatus;
    isOnlineNotifier.value = _isOnline;
    notifyListeners();
  }

  @override
  void dispose() {
    syncStatusNotifier.dispose();
    isOnlineNotifier.dispose();
    lastSyncedAtNotifier.dispose();
    super.dispose();
  }
}