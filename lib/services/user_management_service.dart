import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/roles.dart';
import '../core/constants/status.dart';
import '../models/user/etudiant.dart';
import '../models/user/user.dart';

class UserManagementService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserManagementService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createUser({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    required String role,
    String? filiereId,
    String? niveau,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final user = Utilisateur(
      uid: uid,
      email: email,
      nom: nom,
      prenom: prenom,
      telephone: telephone,
      role: role,
      estActif:
          true, // Les utilisateurs créés par l'admin sont actifs par défaut
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toFirestore());

    if (role == AppRoles.etudiant) {
      final etudiant = Etudiant(
        id: uid,
        userId: uid,
        email: email,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        matricule: null,
        filiereId: filiereId,
        niveau: niveau,
        statutValidation: StatutValidationEtudiant
            .valide, // Validé directement si créé par admin
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dateCreation: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.etudiantsCollection)
          .doc(etudiant.id)
          .set(etudiant.toFirestore());

      // Créer une inscription active pour l'étudiant créé par l'admin
      await _firestore.collection(AppConstants.inscriptionsCollection).add({
        'etudiantId': uid,
        'filiereId': filiereId,
        'niveau': niveau,
        'anneeAcademique': DateTime.now().year.toString(),
        'statut': StatutInscription.active,
        'fraisTotal':
            0.0, // À définir manuellement ou via un mécanisme de frais
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
