class GithubRepoConfig {
  final String owner;
  final String repo;
  final String branch;
  final String contentPath; // dossier dans le repo, ex: "data" ou "content"
  final bool useRawContent; // true = raw.githubusercontent.com

  const GithubRepoConfig({
    required this.owner,
    required this.repo,
    this.branch = 'main',
    this.contentPath = '',
    this.useRawContent = true,
  });

  // URL API GitHub
  String get apiBaseUrl => 'https://api.github.com/repos/$owner/$repo/contents';

  // URL Raw content
  String get rawBaseUrl => 'https://raw.githubusercontent.com/$owner/$repo/$branch';

  String contentListUrl() {
    if (contentPath.isEmpty) {
      return '$apiBaseUrl?ref=$branch';
    }
    return '$apiBaseUrl/$contentPath?ref=$branch';
  }

  String rawFileUrl(String filePath) {
    return '$rawBaseUrl/$filePath';
  }
}

class AppConfig {
  final String appName;
  final String appTagline;
  final GithubRepoConfig github;

  const AppConfig({
    required this.appName,
    required this.appTagline,
    required this.github,
  });

  // Chorale Antsan'ny Fitia
  static const AppConfig current = AppConfig(
    appName: "Chorale Antsan'ny Fitia",
    appTagline: "Paroisse Saint François d'Assise",
    github: GithubRepoConfig(
      owner: 'rindraleon',
      repo: 'Antsan-ny-fitia',
      branch: 'main',
      contentPath: '',      // fichiers à la racine
      useRawContent: true,
    ),
  );

  // Fichiers JSON dans le repo
  static const List<String> songFiles = [
    "Antsan'ny fitia.json",
    "Test style.json",
  ];

  static const String parishName = "Paroisse Saint François d'Assise";
  static const String location = "Tsararivotra Ambalavao";
}
