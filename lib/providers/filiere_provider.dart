import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/academique/annee_academique.dart';
import '../models/academique/filiere.dart';
import 'etudiant_provider.dart';

final filieresProvider = StreamProvider<List<Filiere>>((ref) {
  return ref.watch(firestoreServiceProvider).getFilieres();
});

final anneesAcademiquesProvider = StreamProvider<List<AnneeAcademique>>((ref) {
  return ref.watch(firestoreServiceProvider).getAnneesAcademiques();
});
