import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'config/theme.dart';
import 'services/github_service.dart';
import 'services/sync_service.dart';
import 'services/connectivity_service.dart';
import 'providers/content_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        Provider<GithubService>(create: (_) => GithubService(config: AppConfig.current)),
        Provider<SyncService>(
          create: (context) {
            final connectivityService = context.read<ConnectivityService>();
            final githubService = context.read<GithubService>();
            return SyncService(
              githubService: githubService,
              connectivityService: connectivityService,
            );
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final connectivityService = context.read<ConnectivityService>();
            final githubService = context.read<GithubService>();
            final syncService = context.read<SyncService>();
            return ContentProvider(
              githubService: githubService,
              syncService: syncService,
              connectivityService: connectivityService,
            );
          },
        ),
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
