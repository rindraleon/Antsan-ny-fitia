import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final provider = context.read<ContentProvider>();
    await provider.loadContent();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1A4D3A);
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: primaryGreen.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8)),
                ],
                border: Border.all(color: const Color(0xFFB8956A), width: 3),
              ),
              clipBehavior: Clip.antiAlias,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo_antsan.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: primaryGreen,
                    child: const Icon(Icons.music_note_rounded, size: 54, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              "Chorale Antsan'ny Fitia",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryGreen,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Paroisse Saint François d'Assise",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            Text(
              "Tsararivotra Ambalavao",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Synchronisation GitHub...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
