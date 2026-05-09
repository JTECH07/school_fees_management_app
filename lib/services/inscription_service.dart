// lib/services/inscription_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/status.dart';
import '../models/finance/inscription.dart';

class InscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> creerInscription({
    required String etudiantId,
    required String filiereId,
    required String niveau,
    required String anneeAcademique,
  }) async {
    final inscription = Inscription(
      id: _firestore.collection(AppConstants.inscriptionsCollection).doc().id,
      etudiantId: etudiantId,
      filiereId: filiereId,
      niveau: niveau,
      anneeAcademique: anneeAcademique,
      statut: StatutInscription.enAttente, // Toujours en attente au début
      fraisTotal: 0.0, // Sera défini par l'admin
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.inscriptionsCollection)
        .doc(inscription.id)
        .set(inscription.toFirestore());
  }

  Future<Inscription?> getInscriptionById(String inscriptionId) async {
    final doc = await _firestore
        .collection(AppConstants.inscriptionsCollection)
        .doc(inscriptionId)
        .get();
    if (doc.exists) {
      return Inscription.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }
}
