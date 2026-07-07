# Antsan'ny Fitia v2 – Flutter Android

Livré le 7 juillet 2026

Repo GitHub branché : https://github.com/rindraleon/Antsan-ny-fitia

## Nouveautés v2 (demandées)

1. ✅ **Logo Antsan'ny Fitia – Saint François**
   - assets/images/logo_antsan.jpg
   - Splash screen circulaire avec logo
   - Header Home avec logo 44px
   - Icônes Android mipmap générées (mdpi → xxxhdpi)
     - android/app/src/main/res/mipmap-*/ic_launcher.png

2. ✅ **Export PDF / Partage**
   - share_plus ^9.0.0
   - pdf ^3.11.1
   - printing ^5.13.3
   - Menu ••• dans détail chant :
     - Partager texte
     - Exporter PDF
     - Imprimer
   - Export recueil complet : Paramètres → Exporter tout en PDF
   - PDF inclut : en-tête Chorale, titre, auteur, catégorie, paroles, pied de page

3. ✅ **5 Thèmes**
   - Antsan Vert #1A4D3A (défaut)
   - Bleu Océan #1A3A5C
   - Sepia Lecture #6B4E31 (Merriweather)
   - Sombre Nuit #0D2B1F
   - Bordeaux Chorale #6A1B2A
   - Changement instantané, sauvegardé SharedPreferences
   - Accès : FAB → Thèmes, ou Paramètres → Thème

4. ✅ **Recherche vérifiée**
   - Full-text : titre, paroles, auteur, catégorie
   - Insensible à la casse
   - Temps réel
   - Filtre catégorie combinable
   - Bouton "Effacer les filtres"
   - Compteur "Tous les chants (n)"

## Fonctionnalités complètes

- Lecture GitHub : Antsan'ny fitia.json + Test style.json
- Sync auto : vérifie dernier commit GitHub
- Favoris ❤️ persistant
- Taille texte Aa - / + (14–30pt)
- Offline cache
- Partage chant (texte + PDF)
- Export recueil PDF complet avec table des matières
- 5 thèmes
- Recherche malgache / française

## Lancer

```bash
flutter pub get
flutter run
flutter build apk --release
```

## Arborescence

lib/
  main.dart              // ThemeProvider + 5 thèmes
  models/song.dart
  services/
    github_service.dart
    export_service.dart  // PDF / Share
  providers/content_provider.dart
  screens/
    splash_screen.dart   // logo
    home_screen.dart
    detail_screen.dart   // share menu
    favorites_screen.dart
  widgets/song_card.dart

assets/images/logo_antsan.jpg
android/.../mipmap-*/ic_launcher.png
```

Testé avec 10+ chants du repo (TANORANAO RY RAY, VAVAKA...).
