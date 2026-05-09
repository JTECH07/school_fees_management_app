// lib/providers/rapport_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/remote/firebase/firestore_service.dart';
import 'etudiant_provider.dart'; // Pour firestoreServiceProvider

final adminDashboardStatsProvider = FutureProvider<AdminDashboardStats>((
  ref,
) async {
  return ref.watch(firestoreServiceProvider).getAdminDashboardStats();
});

final rapportFinancierGlobalProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  return ref.watch(firestoreServiceProvider).getRapportFinancierGlobal();
});

final echeancesEnRetardProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final echeances = await ref
      .watch(firestoreServiceProvider)
      .getEcheancesEnRetard();
  // Vous pouvez enrichir ces données avec les informations de l'étudiant si nécessaire
  return echeances
      .map(
        (echeance) => {
          'echeance': echeance,
          // 'etudiant': await ref.read(firestoreServiceProvider).getEtudiantById(echeance.etudiantId), // Exemple d'enrichissement
        },
      )
      .toList();
});
