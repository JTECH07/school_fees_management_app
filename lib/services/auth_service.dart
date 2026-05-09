import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/roles.dart';
import '../core/constants/status.dart';

// Classe pour encapsuler le résultat des opérations d'authentification
class LoginResult {
  const LoginResult({this.user, this.errorMessage});

  final Map<String, dynamic>? user;
  final String? errorMessage;
  bool get isSuccess => user != null;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<LoginResult> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Fetch user role from Firestore
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        return const LoginResult(
          errorMessage: "Profil utilisateur introuvable.",
        );
      }

      final data = userDoc.data() as Map<String, dynamic>;
      if (data['estActif'] == false) {
        await _auth.signOut();
        return const LoginResult(
          errorMessage: 'Votre compte est inactif ou en attente de validation.',
        );
      }

      return LoginResult(
        user: <String, dynamic>{
          'uid': userCredential.user!.uid,
          'email': email,
          'role': data['role'],
          'nom': data['nom'],
          'prenom': data['prenom'],
        },
      );
    } on FirebaseAuthException catch (error) {
      return LoginResult(errorMessage: _mapAuthError(error.code));
    } catch (_) {
      return const LoginResult(
        errorMessage: 'Connexion impossible pour le moment.',
      );
    }
  }

  /// Méthode d'inscription pour créer un nouvel utilisateur et son profil Firestore.
  Future<LoginResult> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    required String role,
    String? filiereId,
    String? niveau,
    String? anneeAcademique,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      // Créer le document utilisateur dans Firestore
      await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
        'uid': uid,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'estActif': false, // Par défaut inactif, l'admin doit valider
      });

      if (role == AppRoles.etudiant) {
        // Créer le document étudiant
        await _firestore
            .collection(AppConstants.etudiantsCollection)
            .doc(uid)
            .set({
              'id': uid,
              'userId': uid,
              'nom': nom,
              'prenom': prenom,
              'email': email,
              'telephone': telephone,
              'matricule': null, // Le matricule est généré par l'admin
              'niveau': niveau,
              'filiereId': filiereId,
              'anneeAcademique': anneeAcademique,
              'statutValidation': StatutValidationEtudiant
                  .enAttente, // En attente de validation admin
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        // Créer l'inscription initiale en attente
        if (filiereId != null && niveau != null) {
          final inscriptionRef = _firestore
              .collection(AppConstants.inscriptionsCollection)
              .doc();
          await inscriptionRef.set({
            'id': inscriptionRef.id,
            'etudiantId': uid,
            'filiereId': filiereId,
            'niveau': niveau,
            'anneeAcademique': anneeAcademique ?? '2026-2027',
            'statut': StatutInscription.enAttente,
            'fraisTotal': 0.0, // Sera défini par l'admin
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return LoginResult(user: {'role': role});
    } on FirebaseAuthException catch (e) {
      return LoginResult(errorMessage: e.message);
    } catch (e) {
      return LoginResult(errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessaie plus tard.';
      default:
        return 'Connexion impossible pour le moment.';
    }
  }
}
