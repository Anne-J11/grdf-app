// lib/init_database.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InitDatabase {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fonction principale pour initialiser toute la base
  static Future<void> initializeDatabase() async {
    try {
      print('🔄 Initialisation de la base de données GRDF...');

      await _createAgences();
      await _createSites();
      await _createTypeInterventions();
      await _createTypeInterventionsDebrief();
      await _createTestUsers();

      print('✅ Base de données initialisée avec succès !');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation : $e');
    }
  }

  // Créer les 3 agences
  static Future<void> _createAgences() async {
    final agences = [
      {'id': 'ai_comtoise', 'nom': 'AI COMTOISE'},
      {'id': 'ai_bourgogne_nord', 'nom': 'AI BOURGOGNE NORD'},
      {'id': 'ai_bourgogne_sud', 'nom': 'AI BOURGOGNE SUD'},
    ];

    for (var agence in agences) {
      await _firestore.collection('agences').doc(agence['id']).set({
        'nom': agence['nom'],
      });
    }
    print('✅ 3 Agences créées');
  }

  // Créer tous les sites
  static Future<void> _createSites() async {
    final sites = [
      // AI COMTOISE
      {'id': 'serre_les_sapins', 'nom': 'Serre Les Sapins', 'agence_id': 'ai_comtoise'},
      {'id': 'brognard', 'nom': 'Brognard', 'agence_id': 'ai_comtoise'},
      {'id': 'vesoul', 'nom': 'Vesoul', 'agence_id': 'ai_comtoise'},
      {'id': 'dole', 'nom': 'Dole', 'agence_id': 'ai_comtoise'},
      {'id': 'perrigny', 'nom': 'Perrigny', 'agence_id': 'ai_comtoise'},
      {'id': 'st_claude', 'nom': 'St Claude', 'agence_id': 'ai_comtoise'},
      {'id': 'pontarlier', 'nom': 'Pontarlier', 'agence_id': 'ai_comtoise'},

      // AI BOURGOGNE NORD
      {'id': 'longvic', 'nom': 'Longvic', 'agence_id': 'ai_bourgogne_nord'},
      {'id': 'montbard', 'nom': 'Montbard', 'agence_id': 'ai_bourgogne_nord'},
      {'id': 'sens', 'nom': 'Sens', 'agence_id': 'ai_bourgogne_nord'},
      {'id': 'moneteau', 'nom': 'Moneteau', 'agence_id': 'ai_bourgogne_nord'},

      // AI BOURGOGNE SUD
      {'id': 'chalon', 'nom': 'Chalon Sur Saône', 'agence_id': 'ai_bourgogne_sud'},
      {'id': 'garchizy', 'nom': 'Garchizy', 'agence_id': 'ai_bourgogne_sud'},
      {'id': 'le_creusot', 'nom': 'Le Creusot', 'agence_id': 'ai_bourgogne_sud'},
      {'id': 'macon', 'nom': 'Macon', 'agence_id': 'ai_bourgogne_sud'},
      {'id': 'paray', 'nom': 'Paray Le Monial', 'agence_id': 'ai_bourgogne_sud'},
    ];

    for (var site in sites) {
      await _firestore.collection('sites').doc(site['id']).set({
        'nom': site['nom'],
        'agence_id': site['agence_id'],
      });
    }
    print('✅ 15 Sites créés');
  }

  // Créer les types d'intervention
  static Future<void> _createTypeInterventions() async {
    final types = [
      {
        'nom': 'Clientèle',
        'champs_specifiques': [
          'Risques spécifiques de l\'activité',
          'Analyse de la tournée avec le salarié',
          'Matériel et outillage',
          'Informations diverses',
        ]
      },
      {
        'nom': 'Maintenance',
        'champs_specifiques': [
          'Durée prévue',
          'Risques spécifiques de l\'activité',
          'Compétences et rôles des membres de l\'équipe (si par équipe)',
          'Documents obligatoires (listings, tournées sur tablette, etc)',
          'Matériel et outillage',
          'Informations diverses',
        ]
      },
      {
        'nom': 'Travaux',
        'champs_specifiques': [
          'Procédure d\'exécution',
          'Durée prévue',
          'Environnement du chantier',
          'Risques spécifiques de l\'activité',
          'Compétences et rôles des membres de l\'équipe',
          'Matériel et outillage',
          'Documents obligatoires (plans, fouilles de soudures, etc)',
          'Informations diverses',
        ]
      },
    ];

    for (var type in types) {
      await _firestore.collection('type_intervention').add(type);
    }
    print('✅ 3 Types d\'intervention créés');
  }

  // Créer les types d'intervention débrief
  static Future<void> _createTypeInterventionsDebrief() async {
    final types = [
      {'nom': 'Clientèle', 'champs_specifiques': ['aleas_rencontres']},
      {'nom': 'Maintenance', 'champs_specifiques': ['aleas_rencontres']},
      {'nom': 'Travaux', 'champs_specifiques': ['aleas_rencontres', 'travaux_statut']},
    ];

    for (var type in types) {
      await _firestore.collection('type_intervention_debrief').add(type);
    }
    print('✅ 3 Types d\'intervention débrief créés');
  }

  // ── Créer les comptes de test ──────────────────────────────────────────────
  static Future<void> _createTestUsers() async {
    final testUsers = [
      {
        'email': 'technicien@grdf-test.fr',
        'password': 'Test1234!',
        'nom': 'Dupont',
        'prenom': 'Jean',
        'role': 'technicien',
        'agence_id': 'ai_comtoise',
        'site_id': 'serre_les_sapins',
      },
      {
        'email': 'referent@grdf-test.fr',
        'password': 'Test1234!',
        'nom': 'Martin',
        'prenom': 'Sophie',
        'role': 'referent',
        'agence_id': 'ai_bourgogne_nord',
        'site_id': 'longvic',
      },
      {
        'email': 'manager@grdf-test.fr',
        'password': 'Test1234!',
        'nom': 'Bernard',
        'prenom': 'Luc',
        'role': 'manager',
        'agence_id': 'ai_bourgogne_sud',
        'site_id': 'chalon',
      },
    ];

    for (var userData in testUsers) {
      try {
        // Créer le compte Firebase Auth
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: userData['email']!,
          password: userData['password']!,
        );

        // Enregistrer dans Firestore
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'email': userData['email'],
          'nom': userData['nom'],
          'prenom': userData['prenom'],
          'role': userData['role'],
          'agence_id': userData['agence_id'],
          'site_id': userData['site_id'],
          'actif': true,
          'date_creation': DateTime.now(),
        });

        print('✅ Compte créé : ${userData['email']} (${userData['role']})');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          print('ℹ️ Compte déjà existant : ${userData['email']}');
        } else {
          print('⚠️ Erreur création compte ${userData['email']} : ${e.message}');
        }
      }
    }

    // Se déconnecter après création pour ne pas rester connecté
    await _auth.signOut();
    print('✅ 3 Comptes de test créés (ou déjà existants)');
    print('');
    print('📋 COMPTES DE TEST :');
    print('   Technicien : technicien@grdf-test.fr / Test1234!');
    print('   Référent   : referent@grdf-test.fr   / Test1234!');
    print('   Manager    : manager@grdf-test.fr     / Test1234!');
  }

  // Vérifier si la BDD est déjà initialisée
  static Future<bool> isDatabaseInitialized() async {
    final agences = await _firestore.collection('agences').limit(1).get();
    return agences.docs.isNotEmpty;
  }

  // Réinitialiser toute la base de données
  static Future<void> resetDatabase() async {
    try {
      print('🗑️ Suppression de toutes les données...');
      await _deleteCollection('agences');
      await _deleteCollection('sites');
      await _deleteCollection('type_intervention');
      await _deleteCollection('type_intervention_debrief');
      await _deleteCollection('users');
      await _deleteCollection('briefs');
      await _deleteCollection('debriefs');
      await _deleteCollection('fichiers');
      print('✅ Base de données réinitialisée !');
    } catch (e) {
      print('❌ Erreur lors de la réinitialisation : $e');
    }
  }

  static Future<void> _deleteCollection(String collectionPath) async {
    final collection = _firestore.collection(collectionPath);
    final snapshots = await collection.get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }
}