import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import '../config/app_config.dart';
import '../config/theme.dart';
import '../widgets/song_card.dart';
import 'detail_screen.dart';
import 'favorites_screen.dart';
import '../services/export_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _fabOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 28),
            child: Column(
              children: [
                Text(
                  AppConfig.current.appName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppConfig.parishName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  AppConfig.location,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ContentProvider>(
              builder: (context, provider, _) {
                return Column(
                  children: [
                    // Offline banner
                    if (provider.isOffline)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wifi_off, size: 18, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Mode hors-ligne – données en cache', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                            TextButton(
                              onPressed: () => provider.syncCheck(),
                              child: const Text('Réessayer', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    if (provider.isSyncing)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primary)),
                            const SizedBox(width: 10),
                            const Text('Synchronisation GitHub…', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    // Search - FIXE
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) {
                          provider.search(v);
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Rechercher un chant...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    provider.search('');
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Categories - FIXES
                    if (provider.categories.isNotEmpty)
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: const Text('Tout'),
                                selected: provider.selectedCategory == null,
                                onSelected: (_) => provider.filterByCategory(null),
                              ),
                            ),
                            ...provider.categories.map((cat) {
                              final selected = provider.selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(cat),
                                  selected: selected,
                                  onSelected: (_) => provider.filterByCategory(selected ? null : cat),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),
                    // Title + fav button - FIXE
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Tous les chants (${provider.items.length})',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                            },
                            icon: Icon(Icons.favorite, size: 16, color: Colors.pink.shade300),
                            label: const Text('Favoris'),
                            style: TextButton.styleFrom(
                              backgroundColor: theme.cardColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // List - DÉFILANTE
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => provider.syncCheck(),
                        color: primary,
                        child: provider.isLoading
                            ? Center(child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: CircularProgressIndicator(color: primary),
                              ))
                        : provider.error != null
                            ? _ErrorCard(error: provider.error!, onRetry: () => provider.loadContent())
                        : provider.items.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Column(
                                    children: [
                                      Icon(Icons.search_off, size: 48, color: theme.hintColor),
                                      const SizedBox(height: 12),
                                      const Text('Aucun chant trouvé'),
                                      if (provider.searchQuery.isNotEmpty || provider.selectedCategory != null)
                                        TextButton(
                                          onPressed: provider.clearFilters,
                                          child: const Text('Effacer les filtres'),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: provider.items.length,
                            itemBuilder: (context, index) {
                              final song = provider.items[index];
                              return SongCard(
                                song: song,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => DetailScreen(song: song)),
                                ),
                              );
                            },
                          ),
                      ),
                    ),
                    // Debug info
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Center(
                        child: Text(
                          '${provider.totalCount} chants ',
                          style: TextStyle(fontSize: 11, color: theme.hintColor),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildFab(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_fabOpen) ...[
          _fabMenuItem(Icons.cloud_download_outlined, 'Synchroniser', () async {
            setState(() => _fabOpen = false);
            final provider = context.read<ContentProvider>();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Synchronisation depuis GitHub...'), duration: Duration(seconds: 1)),
            );
            await provider.syncCheck();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${provider.totalCount} chants synchronisés')),
              );
            }
          }),
          const SizedBox(height: 10),
          _fabMenuItem(Icons.picture_as_pdf, 'Exporter PDF', () async {
            setState(() => _fabOpen = false);
            final songs = context.read<ContentProvider>().allItems;
            if (songs.isEmpty) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Génération PDF...')));
            await ExportService.exportAllSongsPdf(songs);
          }),
          const SizedBox(height: 10),
          _fabMenuItem(Icons.palette_outlined, 'Thèmes', () {
            setState(() => _fabOpen = false);
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => const _ThemeSheet(),
            );
          }),
          const SizedBox(height: 10),
          _fabMenuItem(Icons.settings_outlined, 'Paramètres', () {
            setState(() => _fabOpen = false);
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => const _SettingsSheet(),
            );
          }),
          const SizedBox(height: 10),
        ],
        FloatingActionButton(
          backgroundColor: primary,
          onPressed: () => setState(() => _fabOpen = !_fabOpen),
          child: Icon(_fabOpen ? Icons.close : Icons.menu, color: Colors.white),
        ),
      ],
    );
  }

  Widget _fabMenuItem(IconData icon, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: theme.cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorCard({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.error, size: 40),
            const SizedBox(height: 8),
            const Text('Erreur de synchronisation GitHub'),
            const SizedBox(height: 4),
            Text(error, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choisir un thème', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...AppThemeType.values.map((t) {
            final td = AppThemeData.all[t]!;
            final selected = themeProvider.themeType == t;
            return ListTile(
              leading: CircleAvatar(backgroundColor: td.primary, radius: 16),
              title: Text(td.name),
              subtitle: Text(
                td.brightness == Brightness.dark ? 'Mode sombre' : 'Mode clair',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: selected ? Icon(Icons.check_circle, color: td.primary) : null,
              onTap: () {
                themeProvider.setTheme(t);
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _autoSync = true;
  bool _wifiOnly = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    // valeurs par défaut, sera mis à jour via provider
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Paramètres', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                if (provider.isSyncing)
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: provider.isOffline ? Colors.orange.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: provider.isOffline ? Colors.orange.shade200 : Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Chorale Antsan\'ny Fitia Tsararivotra',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: provider.isOffline ? Colors.orange.shade900 : Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"Mba handefa feo fiderana, ary hitantara ny asanao mahagaga rehetra."',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      color: provider.isOffline ? Colors.orange.shade800 : Colors.green.shade800,
                    ),
                  ),
                  Text(
                    '__Salamo 26,7__',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: provider.isOffline ? Colors.orange.shade700 : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Thème', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppThemeType.values.map((t) {
                  final td = AppThemeData.all[t]!;
                  final selected = themeProvider.themeType == t;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(backgroundColor: td.primary, radius: 10),
                      const SizedBox(width: 6),
                      Checkbox(
                        value: selected,
                        onChanged: (_) => themeProvider.setTheme(t),
                        fillColor: WidgetStateProperty.all(td.primary),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 4),
                        Text(td.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                      const SizedBox(width: 12),
                    ],
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 28),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.text_fields),
              title: const Text('Taille du texte'),
              subtitle: Text('${provider.fontSize.toInt()} pt'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(onPressed: provider.decreaseFont, icon: const Icon(Icons.remove_circle_outline)),
                IconButton(onPressed: provider.increaseFont, icon: const Icon(Icons.add_circle_outline)),
              ]),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.sync),
              title: const Text('Sync auto au démarrage'),
              subtitle: const Text('Charge cache instantané puis MAJ GitHub'),
              value: _autoSync,
              onChanged: (v) async {
                setState(() => _autoSync = v);
                // save via OfflineCacheService
                // ignore: unused_result
                await Future.delayed(Duration.zero);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.wifi),
              title: const Text('Wi-Fi uniquement'),
              subtitle: const Text('Évite données mobiles pour sync'),
              value: _wifiOnly,
              onChanged: (v) => setState(() => _wifiOnly = v),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.favorite, color: Colors.pink),
              title: const Text('Favoris'),
              subtitle: Text('${provider.favoriteIds.length} chants – stockage local'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Exporter PDF'),
              subtitle: Text('${provider.totalCount} chants • ${provider.cacheSizeText}'),
              trailing: const Icon(Icons.download),
              onTap: () async {
                Navigator.pop(context);
                final songs = provider.allItems;
                if (songs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun chant – téléchargez d’abord')));
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Génération PDF…')));
                try {
                  await ExportService.exportAllSongsPdf(songs);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.search),
              title: const Text('Recherche avancée'),
              subtitle: const Text('Multi-mots • offline • instantanée'),
              trailing: Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Copyright by Rindra Léon 2026', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}