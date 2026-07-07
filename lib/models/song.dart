class Song {
  final int id;
  final String title;
  final String lyrics;
  final String author;
  final int? year;
  final String category;
  final String sourceFile;

  Song({
    required this.id,
    required this.title,
    required this.lyrics,
    required this.author,
    this.year,
    required this.category,
    this.sourceFile = '',
  });

  factory Song.fromJson(Map<String, dynamic> json, {String sourceFile = ''}) {
    return Song(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: (json['title'] ?? '').toString().trim(),
      lyrics: (json['lyrics'] ?? json['content'] ?? '').toString(),
      author: (json['author'] ?? 'Inconnu').toString().trim(),
      year: json['year'] is int ? json['year'] : int.tryParse(json['year']?.toString() ?? ''),
      category: (json['category'] ?? 'Divers').toString().trim(),
      sourceFile: sourceFile,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'lyrics': lyrics,
    'author': author,
    'year': year,
    'category': category,
  };

  // Pour compatibilité avec l'ancien ContentItem
  String get content => lyrics;
  String get subtitle => '$category • $author';
  String? get imageUrl => null;
  DateTime? get date => year != null ? DateTime(year!) : null;
}

class SongsResponse {
  final List<Song> songs;
  SongsResponse(this.songs);

  factory SongsResponse.fromJson(dynamic json, {String sourceFile = ''}) {
    if (json is List) {
      return SongsResponse(json.map((e) => Song.fromJson(e, sourceFile: sourceFile)).toList());
    } else if (json is Map<String, dynamic>) {
      // Cherche la clé qui contient la liste
      for (var key in ['songs', 'items', 'data', 'chants', 'hira']) {
        if (json[key] is List) {
          return SongsResponse(
            (json[key] as List).map((e) => Song.fromJson(e as Map<String, dynamic>, sourceFile: sourceFile)).toList(),
          );
        }
      }
      // objet unique
      return SongsResponse([Song.fromJson(json, sourceFile: sourceFile)]);
    }
    return SongsResponse([]);
  }
}
