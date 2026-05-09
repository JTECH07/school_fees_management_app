import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/user/etudiant.dart';
import '../models/user/user.dart';

class ProfileService {
  ProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> updateUtilisateur(Utilisateur utilisateur) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(utilisateur.uid) // Correction: utiliser utilisateur.uid
        .update(<String, dynamic>{
          'nom': utilisateur.nom,
          'prenom': utilisateur.prenom,
        });
  }

  Future<void> updateEtudiant(Etudiant etudiant) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(
          etudiant.userId,
        ) // Correction: utiliser etudiant.userId pour le document user
        .update(<String, dynamic>{
          'nom': etudiant.nom,
          'prenom': etudiant.prenom,
        });

    await _firestore
        .collection(AppConstants.etudiantsCollection)
        .doc(etudiant.id)
        .update(<String, dynamic>{
          'matricule': etudiant.matricule,
          'telephone': etudiant.telephone,
          'adresse': etudiant.adresse,
          'filiereId': etudiant.filiereId, // Correction: utiliser filiereId
          'niveau': etudiant.niveau, // Correction: utiliser niveau
          'commentaireValidation': etudiant.commentaireValidation,
        });
  }
}
