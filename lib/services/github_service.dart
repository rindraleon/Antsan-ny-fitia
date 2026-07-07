import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/content_item.dart';
import '../models/song.dart';

class GithubService {
  final AppConfig config;
  final http.Client _client;

  GithubService({required this.config, http.Client? client})
      : _client = client ?? http.Client();

  GithubRepoConfig get repo => config.github;

  // 1. Lister tous les fichiers de contenu dans le repo
  Future<List<GithubFile>> listContentFiles() async {
    final url = Uri.parse(repo.contentListUrl());
    final response = await _client.get(
      url,
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'flutter-github-reader',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((e) => GithubFile.fromJson(e))
          .where((f) => f.isContentFile)
          .toList();
    } else {
      throw Exception('Erreur GitHub API ${response.statusCode}: ${response.body}');
    }
  }

  // 2. Charger un fichier JSON brut
  Future<dynamic> fetchRawJson(String filePath) async {
    final url = repo.useRawContent
        ? repo.rawFileUrl(filePath)
        : 'https://api.github.com/repos/${repo.owner}/${repo.repo}/contents/$filePath?ref=${repo.branch}';

    final response = await _client.get(Uri.parse(url), headers: {
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Impossible de charger $filePath');
    }

    // Si via API GitHub, le contenu est en base64
    if (!repo.useRawContent && url.contains('api.github.com')) {
      final apiData = json.decode(response.body);
      if (apiData['encoding'] == 'base64') {
        final content = utf8.decode(base64.decode(apiData['content'].replaceAll('\n', '')));
        return json.decode(content);
      }
    }

    return json.decode(response.body);
  }

  // 3. Charger un fichier texte/markdown brut
  Future<String> fetchRawText(String filePath) async {
    final url = Uri.parse(repo.rawFileUrl(filePath));
    final response = await _client.get(url);
    if (response.statusCode == 200) {
      return utf8.decode(response.bodyBytes);
    }
    throw Exception('Erreur chargement texte: ${response.statusCode}');
  }

  // 4. Charger TOUS les contenus
  Future<List<ContentItem>> fetchAllContent() async {
    final files = await listContentFiles();
    List<ContentItem> allItems = [];

    for (final file in files) {
      try {
        if (file.isJson) {
          final data = await fetchRawJson(file.path);
          if (data is List) {
            allItems.addAll(ContentItem.listFromJsonList(data, sourceFile: file.path));
          } else if (data is Map<String, dynamic>) {
            // Supporte aussi { "items": [...] }
            if (data.containsKey('items') && data['items'] is List) {
              allItems.addAll(ContentItem.listFromJsonList(data['items'], sourceFile: file.path));
            } else if (data.containsKey('data') && data['data'] is List) {
              allItems.addAll(ContentItem.listFromJsonList(data['data'], sourceFile: file.path));
            } else {
              // Un seul objet
              allItems.add(ContentItem.fromJson(data, sourceFile: file.path));
            }
          }
        } else if (file.isMarkdown || file.isText) {
          final text = await fetchRawText(file.path);
          // Créer un ContentItem depuis un fichier markdown
          allItems.add(ContentItem(
            id: file.path,
            title: file.name.replaceAll(RegExp(r'\.(md|txt)$'), '').replaceAll('_', ' ').replaceAll('-', ' '),
            subtitle: '',
            content: text,
            rawData: {'file': file.path},
            sourceFile: file.path,
          ));
        }
      } catch (e) {
        // Ignore un fichier corrompu, continue
        continue;
      }
    }

    // Tri par date décroissante si disponible
    allItems.sort((a, b) {
      if (a.date != null && b.date != null) return b.date!.compareTo(a.date!);
      return a.title.compareTo(b.title);
    });

    return allItems;
  }

  // --- SONGS SPECIFIQUE ANTSAN'NY FITIA ---
  // Charge les chants depuis les fichiers connus
  Future<List<Song>> fetchSongs() async {
    List<Song> allSongs = [];
    // Essaye d'abord les fichiers configurés
    for (final fileName in AppConfig.songFiles) {
      try {
        final encoded = Uri.encodeComponent(fileName);
        // rawFileUrl n'encode pas, on fait manuellement
        final url = '${repo.rawBaseUrl}/$encoded';
        final response = await _client.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          final parsed = SongsResponse.fromJson(data, sourceFile: fileName);
          allSongs.addAll(parsed.songs);
        }
      } catch (_) {
        continue;
      }
    }

    // Si rien trouvé, fallback: liste tous les JSON du repo
    if (allSongs.isEmpty) {
      try {
        final files = await listContentFiles();
        for (final f in files.where((x) => x.isJson)) {
          try {
            final data = await fetchRawJson(f.path);
            final parsed = SongsResponse.fromJson(data, sourceFile: f.path);
            allSongs.addAll(parsed.songs);
          } catch (_) {}
        }
      } catch (_) {}
    }

    // Dédupliquer par id+title
    final Map<String, Song> unique = {};
    for (var s in allSongs) {
      unique['${s.id}-${s.title}'] = s;
    }
    allSongs = unique.values.toList();
    // Tri alphabétique
    allSongs.sort((a, b) => a.title.compareTo(b.title));
    return allSongs;
  }

  // Dernière date de commit pour vérifier mise à jour
  Future<DateTime?> getLastCommitDate() async {
    try {
      final url = Uri.parse('https://api.github.com/repos/${repo.owner}/${repo.repo}/commits/${repo.branch}');
      final res = await _client.get(url, headers: {'Accept': 'application/vnd.github.v3+json', 'User-Agent': 'flutter-app'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final dateStr = data['commit']?['committer']?['date'] ?? data['commit']?['author']?['date'];
        if (dateStr != null) return DateTime.parse(dateStr);
      }
    } catch (_) {}
    return null;
  }

  void dispose() {
    _client.close();
  }
}
