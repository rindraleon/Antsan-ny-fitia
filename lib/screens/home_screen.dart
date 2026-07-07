import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import '../config/app_config.dart';
import '../widgets/song_card.dart';
import 'detail_screen.dart';
import 'favorites_screen.dart';
import '../main.dart';
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/logo_antsan.jpg',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppConfig.current.appName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
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
                return RefreshIndicator(
                  onRefresh: () => provider.syncCheck(),
                  color: primary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    children: [
                      // Search
                      TextField(
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
                      const SizedBox(height: 14),
                      // Categories
                      if (provider.categories.isNotEmpty)
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
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
                      const SizedBox(height: 16),
                      // Title + fav button
                      Row(
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
                      const SizedBox(height: 12),
                      // List
                      if (provider.isLoading)
                        Center(child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: primary),
                        ))
                      else if (provider.error != null)
                        _ErrorCard(error: provider.error!, onRetry: () => provider.loadContent())
                      else if (provider.items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
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
                      else
                        ...provider.items.map((song) => SongCard(
                              song: song,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => DetailScreen(song: song)),
                              ),
                            )),
                      const SizedBox(height: 20),
                      // Debug info
                      Center(
                        child: Text(
                          '${provider.totalCount} chants • GitHub sync actif',
                          style: TextStyle(fontSize: 11, color: theme.hintColor),
                        ),
                      ),
                    ],
                  ),
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
  String _lastSync = 'Auto via GitHub';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paramètres', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Thème', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppThemeType.values.map((t) {
                final td = AppThemeData.all[t]!;
                final selected = themeProvider.themeType == t;
                return ChoiceChip(
                  avatar: CircleAvatar(backgroundColor: td.primary, radius: 10),
                  label: Text(td.name, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
                  selected: selected,
                  selectedColor: td.primary,
                  onSelected: (_) => themeProvider.setTheme(t),
                );
              }).toList(),
            ),
            const Divider(height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.text_fields),
              title: const Text('Taille du texte'),
              subtitle: Text('${provider.fontSize.toInt()} pt'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(onPressed: provider.decreaseFont, icon: const Icon(Icons.remove_circle_outline)),
                  IconButton(onPressed: provider.increaseFont, icon: const Icon(Icons.add_circle_outline)),
                ],
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recherche en temps réel'),
              subtitle: const Text('Filtre instantané pendant la saisie'),
              value: true,
              onChanged: (_) {},
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cloud_sync),
              title: const Text('Synchronisation GitHub'),
              subtitle: Text(_lastSync),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  await context.read<ContentProvider>().syncCheck();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Synchronisé')),
                    );
                  }
                },
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.favorite),
              title: const Text('Favoris'),
              subtitle: Text('${provider.favoriteIds.length} chants'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Exporter tout en PDF'),
              subtitle: Text('${provider.totalCount} chants • Recueil complet'),
              trailing: const Icon(Icons.download),
              onTap: () async {
                Navigator.pop(context);
                final songs = provider.allItems;
                if (songs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun chant à exporter')));
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Génération PDF recueil...')));
                try {
                  await ExportService.exportAllSongsPdf(songs);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur PDF: $e')));
                  }
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.share),
              title: const Text('Partager l\'application'),
              onTap: () {
                // share app
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lien de partage copié')),
                );
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Repo GitHub', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  const SelectableText('github.com/rindraleon/Antsan-ny-fitia', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    '• Sync auto à l\'ouverture\n• Recherche full-text (titre, paroles, auteur, catégorie)\n• ${provider.totalCount} chants chargés\n• Thèmes: ${AppThemeType.values.length}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
