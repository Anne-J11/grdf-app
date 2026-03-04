import 'package:flutter/material.dart';
import 'package:grdf_app/auth/screens/login_screen.dart';
import 'package:grdf_app/auth/screens/registration_screen.dart';
import 'auth/component/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Correction du chemin : pas de "../" et ajout de l'extension ".png"
            Image.asset(
              'assets/img/logo.png',
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                return const Text("Fichier logo.png introuvable dans assets/img/");
              },
            ),
            const SizedBox(height: 70),
            const Text(
              'Bienvenue sur l\'application GRDF',
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            CustomButton(
              elevatedButtonText: 'Se connecter',
              textButtonText: 'Pas encore inscrit?',
              elevatedButtonClicked: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()));
              },
              textButtonClicked: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegistrationScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
