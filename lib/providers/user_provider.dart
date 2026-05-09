// lib/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/remote/firebase/firestore_service.dart';
import '../models/user/user.dart';
import 'etudiant_provider.dart'; // Pour firestoreServiceProvider

final userProvider = StreamProvider<List<Utilisateur>>((ref) {
  // L'erreur indiquait un problème de type ici.
  // Assurez-vous que firestoreServiceProvider est bien un Provider<FirestoreService>
  // et que getUtilisateurs retourne Stream<List<Map<String, dynamic>>>
  // qui est ensuite mappé en Stream<List<Utilisateur>>.
  return ref.watch(firestoreServiceProvider).getUtilisateurs();
});
