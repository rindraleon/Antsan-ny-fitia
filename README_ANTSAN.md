# Antsan'ny Fitia – App Flutter

Chorale Antsan'ny Fitia
Paroisse Saint François d'Assise
Tsararivotra Ambalavao

Application Android Flutter qui lit les chants depuis GitHub :
https://github.com/rindraleon/Antsan-ny-fitia

## Fonctionnalités implémentées (d'après vos maquettes)

- ✅ Header vert arrondi "Chorale Antsan'ny Fitia"
- ✅ Recherche "Rechercher un chant..."
- ✅ Filtres catégories : Afrobeats, Ballad, Latin, Pop & Rock, Sud Af, Tropical...
- ✅ Liste cartes : icône 🎵, TITRE MAJUSCULE, "Catégorie • Auteur", chevron
- ✅ Écran détail : AppBar verte, titre chant, ❤️ favori, ▶️ play
- ✅ Paroles sur fond carte blanche, fond gris
- ✅ Bouton Aa flottant → ouvre - / + / X pour taille texte
- ✅ Favoris : écran "Hira tiana (Favoris)" avec message malgache
  - "Tsy mbola misy hira tiana"
  - "Tsindrio ny ❤️ mba hanampy hira"
- ✅ FAB Paramètres vert en bas à droite
  - Synchroniser
  - Paramètres
- ✅ Synchronisation GitHub automatique
  - Détection de nouveau commit
  - Bouton Synchroniser manuel
- ✅ Cache local SharedPreferences (favoris + taille texte + dernier sync)
- ✅ 100% offline après 1er chargement

## Structure JSON supportée

Repo : `rindraleon/Antsan-ny-fitia`
Fichiers :
- `Antsan'ny fitia.json`
- `Test style.json`

Format :
```json
{
  "songs": [
    {
      "id": 1,
      "title": "TANORANAO RY RAY",
      "lyrics": "1- 'Ndreto izahay...",
      "author": "Rindra Léon",
      "year": 2021,
      "category": "Sud Af"
    }
  ]
}
```

Parser accepte aussi : `songs`, `items`, `data`, `chants`, `hira`.

## Lancer

```bash
cd antsan_ny_fitia
flutter pub get
flutter run
# ou
flutter build apk --release
```

APK : `build/app/outputs/flutter-apk/app-release.apk`

## Mise à jour automatique

- À chaque ouverture : vérifie le dernier commit GitHub
- Si nouveau commit > dernier sync → recharge automatique
- Bouton "Synchroniser" dans le FAB force le reload
- Les favoris restent en local

## Couleurs

- Primaire : #1A4D3A
- Fond : #E6F0E1
- Cartes : #FFFFFF
- Texte lyrics : #1A1A1A
- Accent favoris : rouge

## Prochaines étapes possibles

- Audio play (just_audio)
- Export PDF
- Mode nuit
- Partage chant
- Tri par : récent / alphabétique / auteur
- Recherche avancée malgache

---
Généré le 7 juillet 2026 – Arena Agent
