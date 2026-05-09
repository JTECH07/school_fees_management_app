import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/finance/inscription.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/status.dart';
import '../models/user/etudiant.dart';
import '../models/finance/paiement.dart';
import '../models/finance/recu.dart';
import '../models/finance/echeance.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupère l'inscription en attente pour un étudiant donné.
  Future<Inscription?> getPendingInscriptionForEtudiant(
    String etudiantId,
  ) async {
    final querySnapshot = await _firestore
        .collection(AppConstants.inscriptionsCollection)
        .where('etudiantId', isEqualTo: etudiantId)
        .where('statut', isEqualTo: StatutInscription.enAttente)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return Inscription.fromFirestore(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );
    }
    return null;
  }

  // Méthodes pour le modèle Utilisateur (générique)
  Stream<List<Map<String, dynamic>>> getUtilisateurs() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<Map<String, dynamic>?> getUtilisateur(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    return doc.data();
  }

  // Méthodes pour le modèle Etudiant
  Stream<Etudiant?> getEtudiant(String userId) {
    return _firestore
        .collection(AppConstants.etudiantsCollection)
        .doc(userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.exists
              ? Etudiant.fromFirestore(snapshot.data()!, snapshot.id)
              : null,
        );
  }

  Stream<List<Etudiant>> getEtudiants() {
    return _firestore
        .collection(AppConstants.etudiantsCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Etudiant.fromFirestore(doc.data()!, doc.id))
              .toList(),
        );
  }

  // Méthodes pour le modèle Inscription
  Stream<Inscription?> getInscriptionActiveEtudiant(String etudiantId) {
    return _firestore
        .collection(AppConstants.inscriptionsCollection)
        .where('etudiantId', isEqualTo: etudiantId)
        .where('statut', isEqualTo: StatutInscription.active)
        .limit(1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.isNotEmpty
              ? Inscription.fromFirestore(
                  snapshot.docs.first.data(),
                  snapshot.docs.first.id,
                )
              : null,
        );
  }

  // Méthodes pour le modèle Paiement
  Stream<List<Paiement>> getPaiementsEtudiant(String etudiantId) {
    return _firestore
        .collection(AppConstants.paiementsCollection)
        .where('etudiantId', isEqualTo: etudiantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Paiement.fromFirestore(doc.data()!, doc.id))
              .toList(),
        );
  }

  // Méthodes pour le modèle Recu
  Stream<List<Recu>> getRecusEtudiant(String etudiantId) {
    return _firestore
        .collection(AppConstants.recusCollection)
        .where('etudiantId', isEqualTo: etudiantId)
        .orderBy('dateGeneration', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Recu.fromFirestore(doc.data()!, doc.id))
              .toList(),
        );
  }

  // Méthodes pour le modèle Echeance
  Stream<List<Echeance>> getEcheancesInscription(String inscriptionId) {
    return _firestore
        .collection(AppConstants.echeancesCollection)
        .where('inscriptionId', isEqualTo: inscriptionId)
        .orderBy('numero')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Echeance.fromFirestore(doc.data()!, doc.id))
              .toList(),
        );
  }

  // Méthodes pour récupérer des documents bruts (pour RecuService par exemple)
  Future<DocumentSnapshot<Map<String, dynamic>>?> getRawPaiement(
    String paiementId,
  ) async {
    return _firestore
        .collection(AppConstants.paiementsCollection)
        .doc(paiementId)
        .get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getRawEtudiant(
    String etudiantId,
  ) async {
    return _firestore
        .collection(AppConstants.etudiantsCollection)
        .doc(etudiantId)
        .get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getRawInscription(
    String inscriptionId,
  ) async {
    return _firestore
        .collection(AppConstants.inscriptionsCollection)
        .doc(inscriptionId)
        .get();
  }
}
