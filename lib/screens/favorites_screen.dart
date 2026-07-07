import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import '../widgets/song_card.dart';
import 'detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1A4D3A);
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EB),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: const Text('Hira tiana (Favoris)', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ContentProvider>(
        builder: (context, provider, _) {
          final favSongs = provider.allItems.where((s) => provider.favoriteIds.contains('${s.id}-${s.title}')).toList();
          if (favSongs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade500),
                  const SizedBox(height: 16),
                  Text(
                    'Tsy mbola misy hira tiana',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Tsindrio ny ', style: TextStyle(color: Colors.grey.shade600)),
                      const Icon(Icons.favorite, color: Colors.red, size: 18),
                      Text(' mba hanampy hira', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favSongs.length,
            itemBuilder: (context, i) {
              final song = favSongs[i];
              return SongCard(
                song: song,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailScreen(song: song)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
