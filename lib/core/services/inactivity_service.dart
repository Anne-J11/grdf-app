// lib/core/services/inactivity_service.dart
// Déconnecte automatiquement l'utilisateur après une période d'inactivité.
// Utilisation : envelopper l'app avec InactivityWrapper dans main.dart.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/providers/user_provider.dart';
import '../../welcome_screen.dart';

/// Durée d'inactivité avant déconnexion automatique (15 minutes par défaut)
const Duration kInactivityTimeout = Duration(minutes: 15);

/// Widget qui détecte toute interaction utilisateur et réinitialise le timer.
/// À placer autour du contenu principal de l'app (après connexion).
class InactivityWrapper extends StatefulWidget {
  final Widget child;
  const InactivityWrapper({super.key, required this.child});

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Détecte quand l'app revient au premier plan
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetTimer();
    } else if (state == AppLifecycleState.paused) {
      // L'app est en arrière-plan : on laisse le timer tourner
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    _dialogShown = false;
    _timer = Timer(kInactivityTimeout, _onInactivityTimeout);
  }

  Future<void> _onInactivityTimeout() async {
    if (!mounted || _dialogShown) return;

    // Vérifier qu'un utilisateur est bien connecté
    final user = context.read<UserProvider>();
    if (user.uid.isEmpty) return;

    _dialogShown = true;

    // Afficher une alerte avant déconnexion
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Session expirée'),
        content: const Text(
            'Vous avez été inactif pendant 15 minutes. Voulez-vous rester connecté ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Rester connecté'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _logout();
    } else {
      // L'utilisateur veut rester connecté : réinitialiser le timer
      _resetTimer();
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    if (!mounted) return;
    context.read<UserProvider>().clearUser();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listener sur tous les gestes/touches de l'utilisateur
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerUp: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}