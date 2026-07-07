class ContentItem {
  final String id;
  final String title;
  final String subtitle;
  final String content;
  final String? imageUrl;
  final String? category;
  final DateTime? date;
  final String? author;
  final Map<String, dynamic> rawData;
  final String sourceFile;

  ContentItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.content,
    this.imageUrl,
    this.category,
    this.date,
    this.author,
    required this.rawData,
    required this.sourceFile,
  });

  // Parser flexible - s'adapte à plusieurs structures JSON
  factory ContentItem.fromJson(Map<String, dynamic> json, {String sourceFile = ''}) {
    // Essayer plusieurs clés possibles pour être robuste
    String getString(List<String> keys, [String fallback = '']) {
      for (var k in keys) {
        if (json[k] != null) return json[k].toString();
      }
      return fallback;
    }

    DateTime? parseDate() {
      final dateStr = getString(['date', 'created_at', 'published_at', 'timestamp']);
      if (dateStr.isEmpty) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (_) {
        return null;
      }
    }

    return ContentItem(
      id: getString(['id', 'slug', 'uuid', 'title'], DateTime.now().millisecondsSinceEpoch.toString()),
      title: getString(['title', 'name', 'titre', 'heading'], 'Sans titre'),
      subtitle: getString(['subtitle', 'description', 'summary', 'excerpt', 'resume', 'intro'], ''),
      content: getString(['content', 'body', 'text', 'texte', 'markdown', 'article'], ''),
      imageUrl: getString(['image', 'imageUrl', 'cover', 'thumbnail', 'photo']),
      category: getString(['category', 'categorie', 'tag', 'section']),
      author: getString(['author', 'auteur', 'writer']),
      date: parseDate(),
      rawData: json,
      sourceFile: sourceFile,
    );
  }

  // Pour liste JSON (un fichier = un tableau d'items)
  static List<ContentItem> listFromJsonList(List<dynamic> list, {String sourceFile = ''}) {
    return list.map((e) => ContentItem.fromJson(e as Map<String, dynamic>, sourceFile: sourceFile)).toList();
  }
}

// Pour représenter un fichier dans le repo GitHub
class GithubFile {
  final String name;
  final String path;
  final String downloadUrl;
  final String type; // "file" ou "dir"
  final int size;

  GithubFile({
    required this.name,
    required this.path,
    required this.downloadUrl,
    required this.type,
    required this.size,
  });

  factory GithubFile.fromJson(Map<String, dynamic> json) {
    return GithubFile(
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      downloadUrl: json['download_url'] ?? '',
      type: json['type'] ?? 'file',
      size: json['size'] ?? 0,
    );
  }

  bool get isJson => name.endsWith('.json');
  bool get isMarkdown => name.endsWith('.md');
  bool get isText => name.endsWith('.txt');
  bool get isContentFile => isJson || isMarkdown || isText;
}
