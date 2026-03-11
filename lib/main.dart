// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'auth/providers/user_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/archive_service.dart';
import 'core/services/inactivity_service.dart';
import 'firebase_options.dart';
import 'init_database.dart';
import 'welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  bool isInitialized = await InitDatabase.isDatabaseInitialized();
  if (!isInitialized) {
    await InitDatabase.initializeDatabase();
  }

  // Archivage automatique au lancement
  await ArchiveService().lancerArchivageAutomatique();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'GRDF Brief App',
      debugShowCheckedModeBanner: false,
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      // InactivityWrapper enveloppe toute l'app :
      // il détecte l'inactivité et déconnecte après 15 min
      home: InactivityWrapper(
        child: const WelcomeScreen(),
      ),
    );
  }
}