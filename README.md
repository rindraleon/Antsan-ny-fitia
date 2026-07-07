# GitHub Text Reader – Flutter Android

Application Flutter qui lit du contenu texte/JSON directement depuis un dépôt GitHub public (ou privé avec token), sans backend.

Construit pour vous le 7 juillet 2026.

## ✨ Fonctionnalités

- Lecture depuis GitHub API + raw.githubusercontent.com
- Support JSON (objet unique, tableau, ou {items: [...]})
- Support Markdown (.md) et texte brut (.txt)
- Recherche full-text locale
- Filtre par catégories
- Material 3 / Dark mode automatique
- Cache local SharedPreferences (prêt)
- Détail avec Markdown rendering
- Pull-to-refresh

## 📁 Structure du projet

```
lib/
  main.dart
  config/app_config.dart        <-- CONFIGUREZ VOTRE REPO ICI
  models/content_item.dart
  services/github_service.dart
  providers/content_provider.dart
  screens/
    splash_screen.dart
    home_screen.dart
    detail_screen.dart
  widgets/
    content_card.dart
    search_bar_widget.dart
```

## ⚙️ Configuration – 2 minutes

Ouvrez `lib/config/app_config.dart` :

```dart
github: GithubRepoConfig(
  owner: 'VOTRE_USERNAME',
  repo: 'VOTRE_REPO',
  branch: 'main',
  contentPath: 'data',   // dossier où sont vos JSON
  useRawContent: true,
),
```

C'est tout.

### Formats JSON supportés (ultra flexible)

**Option A – tableau :**
```json
[
  {
    "id": "1",
    "title": "Mon premier texte",
    "subtitle": "Un résumé",
    "content": "# Markdown supporté\nDu **texte riche**",
    "category": "Histoire",
    "author": "Auteur",
    "date": "2026-07-01",
    "image": "https://..."
  }
]
```

**Option B – objet unique :**
```json
{
  "title": "Titre",
  "content": "Contenu...",
  "titre": "supporte aussi les clés FR",
  "texte": "...",
  "auteur": "..."
}
```

**Option C – wrapper :**
```json
{ "items": [ ... ] }
```

Le parser accepte : `title/name/titre/heading`, `content/body/text/texte/markdown`, `subtitle/description/summary/excerpt/resume`, etc.

Vous pouvez aussi simplement déposer des `.md` dans le repo – chaque fichier devient un article automatiquement.

## 🚀 Lancer

```bash
flutter pub get
flutter run
```

Android :
```bash
flutter build apk --release
# APK dans build/app/outputs/flutter-apk/app-release.apk
```

## 🔐 Repo privé ?

Dans `github_service.dart`, ajoutez :
```dart
headers: {
  'Authorization': 'Bearer VOTRE_GITHUB_TOKEN',
  ...
}
```

## 📦 Dépendances

- http
- provider
- shared_preferences
- cached_network_image
- flutter_markdown
- google_fonts
- intl
- shimmer

---

Besoin que j'adapte le design à votre image ? Envoyez l'image du design, et l'URL GitHub exacte, je mappe le tout pixel-perfect.
