import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_config.dart';
import 'services/github_service.dart';
import 'providers/content_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

enum AppThemeType { green, blue, sepia, dark, burgundy }

class AppThemeData {
  final String name;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color card;
  final Color text;
  final Brightness brightness;
  final String fontFamily;

  const AppThemeData({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.card,
    required this.text,
    this.brightness = Brightness.light,
    this.fontFamily = 'poppins',
  });

  static const green = AppThemeData(
    name: 'Antsan Vert',
    primary: Color(0xFF1A4D3A),
    secondary: Color(0xFF6B8E6B),
    background: Color(0xFFE6F0E1),
    card: Colors.white,
    text: Color(0xFF1A2E1A),
  );

  static const blue = AppThemeData(
    name: 'Bleu Océan',
    primary: Color(0xFF1A3A5C),
    secondary: Color(0xFF4A7BA7),
    background: Color(0xFFE1ECF5),
    card: Colors.white,
    text: Color(0xFF1A2A3A),
  );

  static const sepia = AppThemeData(
    name: 'Sepia Lecture',
    primary: Color(0xFF6B4E31),
    secondary: Color(0xFFA67C52),
    background: Color(0xFFF5EBD6),
    card: Color(0xFFFFF8E7),
    text: Color(0xFF3E2723),
    fontFamily: 'serif',
  );

  static const dark = AppThemeData(
    name: 'Sombre Nuit',
    primary: Color(0xFF0D2B1F),
    secondary: Color(0xFF4CAF50),
    background: Color(0xFF121212),
    card: Color(0xFF1E1E1E),
    text: Color(0xFFE0E0E0),
    brightness: Brightness.dark,
  );

  static const burgundy = AppThemeData(
    name: 'Bordeaux Chorale',
    primary: Color(0xFF6A1B2A),
    secondary: Color(0xFFB03A48),
    background: Color(0xFFF9E9EC),
    card: Colors.white,
    text: Color(0xFF2C0A12),
  );

  static const Map<AppThemeType, AppThemeData> all = {
    AppThemeType.green: green,
    AppThemeType.blue: blue,
    AppThemeType.sepia: sepia,
    AppThemeType.dark: dark,
    AppThemeType.burgundy: burgundy,
  };
}

class ThemeProvider extends ChangeNotifier {
  AppThemeType _themeType = AppThemeType.green;
  ThemeMode _mode = ThemeMode.light;

  AppThemeType get themeType => _themeType;
  ThemeMode get themeMode => _mode;

  AppThemeData get current => AppThemeData.all[_themeType]!;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('app_theme');
    if (t != null) {
      _themeType = AppThemeType.values.firstWhere(
        (e) => e.name == t,
        orElse: () => AppThemeType.green,
      );
      notifyListeners();
    }
  }

  Future<void> setTheme(AppThemeType type) async {
    _themeType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', type.name);
    notifyListeners();
  }

  void toggleDark() {
    if (_themeType == AppThemeType.dark) {
      setTheme(AppThemeType.green);
    } else {
      setTheme(AppThemeType.dark);
    }
  }

  ThemeData get themeData {
    final td = current;
    final isDark = td.brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: td.brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: td.primary,
        brightness: td.brightness,
        primary: td.primary,
        secondary: td.secondary,
        surface: td.card,
        background: td.background, // ignore deprecated
      ),
      scaffoldBackgroundColor: td.background,
      textTheme: td.fontFamily == 'serif'
          ? GoogleFonts.merriweatherTextTheme(isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme)
          : GoogleFonts.poppinsTextTheme(isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: td.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: td.card,
        elevation: isDark ? 1 : 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: td.card,
        hintStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: td.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: td.card,
        selectedColor: td.secondary.withOpacity(0.2),
        side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        labelStyle: TextStyle(color: td.text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: td.primary,
        foregroundColor: Colors.white,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: td.text,
        displayColor: td.text,
      ),
      iconTheme: IconThemeData(color: td.primary),
      listTileTheme: ListTileThemeData(
        iconColor: td.primary,
        textColor: td.text,
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContentProvider(
          githubService: GithubService(config: AppConfig.current),
        )),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConfig.current.appName,
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
