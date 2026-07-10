import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import '../widgets/song_card.dart';
import 'detail_screen.dart';
import '../config/theme.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final primary = theme.colorScheme.primary;
    final isSepia = themeProvider.themeType == AppThemeType.sepia;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('Hira tiana (Favoris)', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: Consumer<ContentProvider>(
        builder: (context, provider, _) {
          final favSongs = provider.allItems.where((s) => provider.isFavorite(s)).toList();
          if (favSongs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 72,
                      color: isDark ? Colors.grey.shade600 : const Color(0xFFA68A6A),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tsy mbola misy hira tiana',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Tsindrio ny ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const Icon(Icons.favorite, color: Colors.red, size: 18),
                        Text(
                          ' mba hanampy hira',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.library_music),
                      label: const Text('Hijery hira'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: [
              // Header info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(isDark ? 0.5 : 1),
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.pink.shade300, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${favSongs.length} hira tiana',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    if (!isDark)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          themeProvider.current.name,
                          style: TextStyle(fontSize: 10, color: primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favSongs.length,
                  itemBuilder: (context, i) {
                    final song = favSongs[i];
                    return Dismissible(
                      key: ValueKey('fav_${song.id}_${song.title}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.heart_broken, color: Colors.white),
                            SizedBox(height: 4),
                            Text('Esorina', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Esorina amin’ny favoris?'),
                            content: Text('"${song.title}"'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Aoka')),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Eny, esory'),
                              ),
                            ],
                          ),
                        ) ?? false;
                      },
                      onDismissed: (_) {
                        context.read<ContentProvider>().toggleFavorite(song);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${song.title} nesorina tamin’ny favoris'),
                            action: SnackBarAction(
                              label: 'Annuler',
                              onPressed: () => context.read<ContentProvider>().toggleFavorite(song),
                            ),
                          ),
                        );
                      },
                      child: SongCard(
                        song: song,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DetailScreen(song: song)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
