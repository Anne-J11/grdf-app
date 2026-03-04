import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'auth/providers/user_provider.dart';
import 'core/services/archive_service.dart';
import 'init_database.dart';
import 'welcome_screen.dart';
import 'firebase_options.dart'; // à générer

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ✅
  );

  bool isInitialized = await InitDatabase.isDatabaseInitialized();
  if (!isInitialized) {
    await InitDatabase.initializeDatabase();
  }

  // Archivage automatique au lancement
  await ArchiveService().lancerArchivageAutomatique();

  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GRDF Brief App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WelcomeScreen(),
    );
  }
}
