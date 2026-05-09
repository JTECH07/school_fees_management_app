import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/status.dart';
import '../models/finance/paiement.dart';
import '../services/paiement_service.dart';
import 'etudiant_provider.dart';

final paiementServiceProvider = Provider<PaiementService>(
  (ref) => PaiementService(),
);

final paiementsProvider = StreamProvider<List<Paiement>>((ref) {
  return ref.watch(firestoreServiceProvider).getAllPaiements();
});

// Provider pour les paiements en attente de validation (pour la secrétaire)
final pendingPaiementsProvider = StreamProvider<List<Paiement>>((ref) {
  return FirebaseFirestore.instance
      .collection(AppConstants.paiementsCollection)
      .where('statut', isEqualTo: StatutPaiementValue.enAttente)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Paiement.fromFirestore(doc.data()!, doc.id))
            .toList(),
      );
});
