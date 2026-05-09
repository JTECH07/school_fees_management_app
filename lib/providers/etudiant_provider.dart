import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/remote/firebase/firestore_service.dart'; // Corrected import path
import '../models/finance/echeance.dart';
import '../models/finance/inscription.dart';
import '../models/finance/paiement.dart';
import '../models/finance/recu.dart';
import '../models/user/etudiant.dart';
import '../models/user/user.dart';
import 'auth_provider.dart'; // Pour obtenir l'ID de l'utilisateur actuel

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

final currentUserIdProvider = Provider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUser()?.uid;
});

final currentUtilisateurProvider = FutureProvider<Utilisateur?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return null;
  }

  final data = await ref
      .read(firestoreServiceProvider)
      .getUtilisateur(userId); // Use read for FutureProvider
  return data;
});

final utilisateursProvider = StreamProvider<List<Utilisateur>>((ref) {
  return ref
      .watch(firestoreServiceProvider)
      .getUtilisateurs();
});

// Provider pour l'étudiant actuellement connecté
final currentEtudiantProvider = StreamProvider<Etudiant?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream<Etudiant?>.value(null);
  }

  return ref.watch(firestoreServiceProvider).getEtudiant(userId);
});

final allEtudiantsProvider = StreamProvider<List<Etudiant>>((ref) {
  return ref.watch(firestoreServiceProvider).getEtudiants();
});

final etudiantProvider = StreamProvider.family<Etudiant?, String>((ref, etudiantId) {
  return ref.watch(firestoreServiceProvider).getEtudiant(etudiantId);
});

final activeInscriptionProvider = StreamProvider.family<Inscription?, String>((
  ref,
  etudiantId,
) {
  return ref
      .watch(firestoreServiceProvider)
      .getInscriptionActiveEtudiant(etudiantId);
});

final inscriptionActiveEtudiantProvider = activeInscriptionProvider;

final paiementsEtudiantProvider = StreamProvider.family<List<Paiement>, String>(
  (ref, etudiantId) {
    return ref.watch(firestoreServiceProvider).getPaiementsEtudiant(etudiantId);
  },
);

final recusEtudiantProvider = StreamProvider.family<List<Recu>, String>((
  ref,
  etudiantId,
) {
  return ref.watch(firestoreServiceProvider).getRecusEtudiant(etudiantId);
});

final allRecusProvider = StreamProvider<List<Recu>>((ref) {
  return ref.watch(firestoreServiceProvider).getAllRecus();
});

final echeancesInscriptionProvider =
    StreamProvider.family<List<Echeance>, String>((ref, inscriptionId) {
      return ref
          .watch(firestoreServiceProvider)
          .getEcheancesInscription(inscriptionId);
    });
