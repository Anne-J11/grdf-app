// lib/auth/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Stream de l'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Inscription
  Future<UserModel> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String role,
    required String agenceId,
    required String siteId,
  }) async {
    try {
      // 1. Créer le compte Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Créer l'objet UserModel
      UserModel user = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        nom: nom,
        prenom: prenom,
        role: role,
        agenceId: agenceId,
        siteId: siteId,
        actif: true,
        dateCreation: DateTime.now(),
      );

      // 3. Enregistrer dans Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toFirestore());

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  // Connexion
  Future<UserModel> login(String email, String password) async {
    try {
      // 1. Se connecter avec Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Récupérer les données depuis Firestore
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!doc.exists) {
        throw Exception('Utilisateur introuvable dans la base de données');
      }

      // 3. Créer l'objet UserModel
      return UserModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  // Déconnexion
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  // Récupérer les données de l'utilisateur actuel
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUser == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!doc.exists) return null;

      return UserModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      print('Erreur lors de la récupération des données: $e');
      return null;
    }
  }

  // Mettre à jour les données utilisateur
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  // Réinitialiser le mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de la réinitialisation: $e');
    }
  }

  // Gestion des erreurs Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'invalid-email':
        return 'Email invalide';
      case 'weak-password':
        return 'Mot de passe trop faible (minimum 6 caractères)';
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }
}