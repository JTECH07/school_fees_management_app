// lib/services/demo_setup_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/roles.dart';
import '../core/constants/status.dart';
import '../models/academique/annee_academique.dart';
import '../models/academique/filiere.dart';
import '../models/finance/inscription.dart';
import '../models/user/etudiant.dart';
import '../models/user/user.dart';

class DemoAccount {
  final String role;
  final String email;
  final String password;
  final String description;

  DemoAccount({
    required this.role,
    required this.email,
    required this.password,
    required this.description,
  });
}

class DemoSetupResult {
  final String message;
  final List<DemoAccount> accounts;

  DemoSetupResult({required this.message, required this.accounts});
}


class DemoSetupService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DemoSetupResult> setupDemoData() async {
    // 1. Nettoyer les données existantes (optionnel, pour un setup propre)
    await _cleanUpDemoData();

    final List<DemoAccount> createdAccounts = [];

    // 2. Créer les utilisateurs de démo (Auth et Firestore)
    // Admin
    await _createDemoUser(
      email: 'demo_admin@uatm.test',
      password: 'password',
      nom: 'Admin',
      prenom: 'Démo',
      role: AppRoles.admin,
      estActif: true,
    );
    createdAccounts.add(
      DemoAccount(
        role: AppRoles.admin,
        email: 'demo_admin@uatm.test',
        password: 'password',
        description: 'Compte Administrateur',
      ),
    );

    // Secrétaire
    await _createDemoUser(
      email: 'demo_secretaire@uatm.test',
      password: 'password',
      nom: 'Secrétaire',
      prenom: 'Démo',
      role: AppRoles.secretaire,
      estActif: true,
    );
    createdAccounts.add(
      DemoAccount(
        role: AppRoles.secretaire,
        email: 'demo_secretaire@uatm.test',
        password: 'password',
        description: 'Compte Secrétaire',
      ),
    );

    // Étudiant
    final etudiantUser = await _createDemoUser(
      email: 'demo_etudiant@uatm.test',
      password: 'password',
      nom: 'Étudiant',
      prenom: 'Démo',
      role: AppRoles.etudiant,
      estActif: false, // En attente de validation admin
    );
    createdAccounts.add(
      DemoAccount(
        role: AppRoles.etudiant,
        email: 'demo_etudiant@uatm.test',
        password: 'password',
        description: 'Compte Étudiant (en attente de validation)',
      ),
    );

    // 3. Créer le profil étudiant dans Firestore (en attente de validation)
    final etudiantProfile = Etudiant(
      id: etudiantUser.uid,
      userId: etudiantUser.uid,
      nom: etudiantUser.nom,
      prenom: etudiantUser.prenom,
      email: etudiantUser.email,
      telephone: '0123456789',
      matricule: null, // Sera généré par l'admin
      filiereId: 'IRT', // Filière souhaitée
      niveau: 'L1', // Niveau souhaité
      statutValidation: StatutValidationEtudiant.enAttente,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _firestore
        .collection(AppConstants.etudiantsCollection)
        .doc(etudiantProfile.id)
        .set(etudiantProfile.toFirestore());

    // 4. Créer une filière de démo
    final filiereIRT = Filiere(
      id: 'filiere_irt_id',
      nom: 'Informatique et Réseaux Télécoms',
      code: 'IRT',
      fraisParNiveau: {
        'L1': 500000.0,
        'L2': 500000.0,
        'L3': 550000.0,
        'M1': 600000.0,
        'M2': 650000.0,
      },
    );
    await _firestore
        .collection(AppConstants.filieresCollection)
        .doc(filiereIRT.id)
        .set(filiereIRT.toFirestore());

    // 5. Créer une année académique de démo
    final annee2025 = AnneeAcademique(
      id: 'annee_2025_2026',
      libelle: '2025-2026',
      dateDebut: DateTime(2025, 10, 1),
      dateFin: DateTime(2026, 7, 31),
      estFermee: false,
    );
    await _firestore
        .collection(AppConstants.anneesAcademiquesCollection)
        .doc(annee2025.id)
        .set(annee2025.toFirestore());

    // 6. Créer une inscription de démo (en attente de validation)
    final inscriptionEtudiant = Inscription(
      id: 'inscription_etudiant_demo_id',
      etudiantId: etudiantUser.uid,
      filiereId: filiereIRT.id,
      niveau: 'L1',
      anneeAcademique: annee2025.libelle,
      statut: StatutInscription.enAttente,
      fraisTotal: 0.0, // Sera défini par l'admin
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _firestore
        .collection(AppConstants.inscriptionsCollection)
        .doc(inscriptionEtudiant.id)
        .set(inscriptionEtudiant.toFirestore());

    // 7. Créer un compteur pour les matricules
    await _firestore.collection('settings').doc('counters').set({
      'student_count': 0,
    }, SetOptions(merge: true));

    return DemoSetupResult(
      message: 'Données de démonstration créées avec succès !',
      accounts: createdAccounts,
    );
  }

  Future<Utilisateur> _createDemoUser({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String role,
    required bool estActif,
  }) async {
    UserCredential userCredential;
    try {
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Si l'utilisateur existe déjà, on le supp55%rime et on le recrée
        try {
          await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          await _auth.currentUser?.delete();
          await _auth.signOut();
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } catch (_) {
          // Si on ne peut pas se connecter (ex: mot de passe différent), on récupère l'UID via Firestore
          final query = await _firestore.collection(AppConstants.usersCollection).where('email', isEqualTo: email).limit(1).get();
          if (query.docs.isNotEmpty) {
             final uid = query.docs.first.id;
             final user = Utilisateur(
                uid: uid,
                email: email,
                nom: nom,
                prenom: prenom,
                telephone: 'N/A',
                role: role,
                estActif: estActif,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await _firestore
                  .collection(AppConstants.usersCollection)
                  .doc(uid)
                  .set(user.toFirestore());
              return user;
          }
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    final uid = userCredential.user!.uid;
    final user = Utilisateur(
      uid: uid,
      email: email,
      nom: nom,
      prenom: prenom,
      telephone: 'N/A',
      role: role,
      estActif: estActif,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(user.toFirestore());

    return user;
  }

  Future<void> _cleanUpDemoData() async {
    // Supprimer les utilisateurs de démo dans Auth
    final demoEmails = [
      'demo_admin@uatm.test',
      'demo_secretaire@uatm.test',
      'demo_etudiant@uatm.test',
    ];

    for (final email in demoEmails) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: 'password',
        );
        await _auth.currentUser?.delete();
      } catch (e) {
        // Ignorer si l'utilisateur n'existe pas
      }
    }

    // Supprimer les collections de démo dans Firestore
    await _deleteCollection(AppConstants.usersCollection);
    await _deleteCollection(AppConstants.etudiantsCollection);
    await _deleteCollection(AppConstants.inscriptionsCollection);
    await _deleteCollection(AppConstants.paiementsCollection);
    await _deleteCollection(AppConstants.echeancesCollection);
    await _deleteCollection(AppConstants.recusCollection);
    await _deleteCollection(AppConstants.filieresCollection);
    await _deleteCollection(AppConstants.anneesAcademiquesCollection);
    await _firestore.collection('settings').doc('counters').delete();
  }

  Future<void> _deleteCollection(String collectionPath) async {
    final collectionRef = _firestore.collection(collectionPath);
    final snapshot = await collectionRef.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
