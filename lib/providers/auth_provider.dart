import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUser();
});

final userRoleProvider = FutureProvider<String?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final user = authService.getCurrentUser();

  if (user == null) return null;

  // Récupérer le rôle depuis Firestore
  final userDoc = await FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .doc(user.uid)
      .get();

  if (!userDoc.exists) {
    return null;
  }

  final data = userDoc.data();
  return data?['role'] as String?;
});
