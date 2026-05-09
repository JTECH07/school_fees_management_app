import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user/etudiant.dart';
import '../services/admin_service.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/status.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

// Provider pour récupérer les étudiants en attente de validation
final pendingEtudiantsProvider = StreamProvider<List<Etudiant>>((ref) {
  return FirebaseFirestore.instance
      .collection(AppConstants.etudiantsCollection)
      .where('statutValidation', isEqualTo: StatutValidationEtudiant.enAttente)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Etudiant.fromFirestore(doc.data(), doc.id))
            .toList(),
      );
});
