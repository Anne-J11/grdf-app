import 'package:cloud_firestore/cloud_firestore.dart';

class InitDatabase {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fonction principale pour initialiser toute la base
  static Future<void> initializeDatabase() async {
    try {
      print('🔄 Initialisation de la base de données GRDF...');

      await _createAgences();
      await _createSites();
      await _createTypeInterventions();
      await _createTypeInterventionsDebrief();

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
      {'nom': 'Serre Les Sapins', 'agence_id': 'ai_comtoise'},
      {'nom': 'Brognard', 'agence_id': 'ai_comtoise'},
      {'nom': 'Vesoul', 'agence_id': 'ai_comtoise'},
      {'nom': 'Dole', 'agence_id': 'ai_comtoise'},
      {'nom': 'Perrigny', 'agence_id': 'ai_comtoise'},
      {'nom': 'St Claude', 'agence_id': 'ai_comtoise'},

      // AI BOURGOGNE NORD
      {'nom': 'Longvic', 'agence_id': 'ai_bourgogne_nord'},
      {'nom': 'Montbard', 'agence_id': 'ai_bourgogne_nord'},
      {'nom': 'Sens', 'agence_id': 'ai_bourgogne_nord'},
      {'nom': 'Moneteau', 'agence_id': 'ai_bourgogne_nord'},

      // AI BOURGOGNE SUD
      {'nom': 'Chalon Sur Saône', 'agence_id': 'ai_bourgogne_sud'},
      {'nom': 'Garchizy', 'agence_id': 'ai_bourgogne_sud'},
      {'nom': 'Le Creusot', 'agence_id': 'ai_bourgogne_sud'},
      {'nom': 'Macon', 'agence_id': 'ai_bourgogne_sud'},
      {'nom': 'Paray Le Monial', 'agence_id': 'ai_bourgogne_sud'},
    ];

    for (var site in sites) {
      await _firestore.collection('sites').add(site);
    }
    print('✅ 15 Sites créés');
  }

  // Créer les types d'intervention avec leurs champs spécifiques
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
    print('✅ 3 Types d\'intervention créés (Clientèle, Maintenance, Travaux)');
  }

  // Créer les types d'intervention pour le débrief (collection séparée)
  static Future<void> _createTypeInterventionsDebrief() async {
    final types = [
      {
        'nom': 'Clientèle',
        'champs_specifiques': ['aleas_rencontres'],
      },
      {
        'nom': 'Maintenance',
        'champs_specifiques': ['aleas_rencontres'],
      },
      {
        'nom': 'Travaux',
        'champs_specifiques': ['aleas_rencontres', 'travaux_statut'],
      },
    ];

    for (var type in types) {
      await _firestore.collection('type_intervention_debrief').add(type);
    }
    print('✅ 3 Types d\'intervention débrief créés');
  }

  // Fonction pour vérifier si la BDD est déjà initialisée
  static Future<bool> isDatabaseInitialized() async {
    final agences = await _firestore.collection('agences').limit(1).get();
    return agences.docs.isNotEmpty;
  }

  // Fonction pour supprimer toutes les données (pour réinitialiser)
  static Future<void> resetDatabase() async {
    try {
      print('🗑️ Suppression de toutes les données...');

      // Supprimer toutes les collections
      await _deleteCollection('agences');
      await _deleteCollection('sites');
      await _deleteCollection('type_intervention');
      await _deleteCollection('users');
      await _deleteCollection('briefs');
      await _deleteCollection('debriefs');
      await _deleteCollection('fichiers');

      print('✅ Base de données réinitialisée !');
    } catch (e) {
      print('❌ Erreur lors de la réinitialisation : $e');
    }
  }

  // Fonction utilitaire pour supprimer une collection
  static Future<void> _deleteCollection(String collectionPath) async {
    final collection = _firestore.collection(collectionPath);
    final snapshots = await collection.get();

    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }
}