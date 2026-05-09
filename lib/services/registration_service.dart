import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/status.dart';
import '../core/constants/app_constants.dart';
import '../models/user/etudiant.dart';
import '../models/user/user.dart';

class RegistrationInput {
  const RegistrationInput({
    required this.email,
    required this.password,
    required this.nom,
    required this.prenom,
    required this.role,
    this.matricule,
    this.telephone,
    this.adresse,
    this.filiereSouhaiteeId,
    this.niveauSouhaite,
    this.anneeAcademiqueSouhaitee,
  });

  final String email;
  final String password;
  final String nom;
  final String prenom;
  final String role;
  final String? matricule;
  final String? telephone;
  final String? adresse;
  final String? filiereSouhaiteeId;
  final String? niveauSouhaite;
  final String? anneeAcademiqueSouhaitee;
}

class RegistrationService {
  RegistrationService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> register(RegistrationInput input) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: input.email,
      password: input.password,
    );

    final user = Utilisateur(
      uid: credential.user!.uid,
      email: input.email,
      nom: input.nom,
      prenom: input.prenom,
      role: input.role,
      estActif: false,
      telephone: input.telephone ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toFirestore());

    if (input.role == 'etudiant') {
      final etudiant = Etudiant(
        id: user.uid,
        userId: user.uid,
        email: user.email,
        nom: user.nom,
        prenom: user.prenom,
        matricule: input.matricule,
        telephone: input.telephone ?? '',
        adresse: input.adresse,
        filiereId: input.filiereSouhaiteeId,
        niveau: input.niveauSouhaite,
        statutValidation: StatutValidationEtudiant.enAttente,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dateCreation: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.etudiantsCollection)
          .doc(etudiant.id)
          .set(etudiant.toFirestore());
    }

    await _auth.signOut();
  }
}
