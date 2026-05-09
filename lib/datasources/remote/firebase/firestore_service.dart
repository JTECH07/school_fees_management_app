// lib/datasources/remote/firebase/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uatm_paiements/core/constants/status.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/academique/filiere.dart';
import '../../../models/academique/annee_academique.dart';
import '../../../models/finance/echeance.dart';
import '../../../models/user/etudiant.dart';
import '../../../models/finance/inscription.dart';
import '../../../models/finance/paiement.dart';
import '../../../models/finance/recu.dart';
import '../../../models/user/user.dart';

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.utilisateurs,
    required this.etudiants,
    required this.inscriptionsActives,
    required this.paiementsValides,
  });

  final int utilisateurs;
  final int etudiants;
  final int inscriptionsActives;
  final int paiementsValides;
}

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  FirebaseFirestore get firestore => _firestore;


  Future<Utilisateur?> getUtilisateur(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return Utilisateur.fromFirestore(doc.data()!, doc.id);
  }

  Stream<List<Utilisateur>> getUtilisateurs() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .orderBy('nom')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Utilisateur.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> saveUtilisateur(Utilisateur utilisateur) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(utilisateur.uid)
        .set(utilisateur.toFirestore(), SetOptions(merge: true));
  }

  Future<void> updateUtilisateurStatus({
    required String userId,
    required bool estActif,
  }) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update(<String, dynamic>{'estActif': estActif});
  }

  // ============ ÉTUDIANTS ============
  Stream<Etudiant?> getEtudiant(String userId) {
    return _firestore
        .collection(AppConstants.etudiantsCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return Etudiant.fromFirestore(doc.data()!, doc.id);
          }
          return null;
        });
  }

  Stream<List<Etudiant>> getEtudiants() {
    return _firestore
        .collection(AppConstants.etudiantsCollection)
        .orderBy('nom')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Etudiant.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  Future<Etudiant?> getEtudiantById(String etudiantId) async {
    final doc = await _firestore
        .collection(AppConstants.etudiantsCollection)
        .doc(etudiantId)
        .get();
    if (!doc.exists) {
      return null;
    }
    return Etudiant.fromFirestore(doc.data()!, doc.id);
  }

  Future<void> saveEtudiantProfile(Etudiant etudiant) async {
    await _firestore
        .collection(AppConstants.etudiantsCollection)
        .doc(etudiant.id)
        .set(etudiant.toFirestore(), SetOptions(merge: true));
  }

  Future<void> updateEtudiantValidation({
    required String etudiantId,
    required String statutValidation,
    String? commentaireValidation,
    required bool estActif,
  }) async {
    await _firestore
        .collection(AppConstants.etudiantsCollection)
        .doc(etudiantId)
        .set(<String, dynamic>{
          'statutValidation': statutValidation,
          'commentaireValidation': commentaireValidation,
        }, SetOptions(merge: true));

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(etudiantId)
        .update(<String, dynamic>{'estActif': estActif});
  }

  Future<Inscription?> getPendingInscriptionForEtudiant(String etudiantId) async {
    final query = await _firestore
        .collection(AppConstants.inscriptionsCollection)
        .where('etudiantId', isEqualTo: etudiantId)
        .where('statut', isEqualTo: 'en_attente')
        .limit(1)
        .get();
    
    if (query.docs.isEmpty) {
      return null;
    }
    
    return Inscription.fromFirestore(query.docs.first.data(), query.docs.first.id);
  }

  // ============ INSCRIPTIONS ============
  Stream<List<Inscription>> getInscriptionsEtudiant(String etudiantId) {
    return _firestore
        .collection(AppConstants.inscriptionsCollection)
        .where('etudiantId', isEqualTo: etudiantId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Inscription.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  Stream<Inscription?> getInscriptionActiveEtudiant(String etudiantId) {
    return _firestore
        .collection(AppConstants.inscriptionsCollection)
        .where('etudiantId', isEqualTo: etudiantId)
        .where('statut', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }

          final doc = snapshot.docs.first;
          return Inscription.fromFirestore(doc.data(), doc.id);
        });
  }

  Stream<List<Echeance>> getEcheancesInscription(String inscriptionId) {
    return _firestore
        .collection(AppConstants.echeancesCollection)
        .where('inscriptionId', isEqualTo: inscriptionId)
        .orderBy('numero')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Echeance.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  Future<List<Echeance>> getEcheancesEnRetard() async {
    final snapshot = await _firestore
        .collection(AppConstants.echeancesCollection)
        .where('statut', isEqualTo: 'retard')
        .get();

    return snapshot.docs
        .map((doc) => Echeance.fromFirestore(doc.data(), doc.id))
        .toList()
      ..sort((a, b) => a.dateLimite.compareTo(b.dateLimite));
  }

  // ============ PAIEMENTS ============
  Future<void> ajouterPaiement(Paiement paiement) async {
    await _firestore
        .collection(AppConstants.paiementsCollection)
        .doc(paiement.id)
        .set(paiement.toFirestore());
  }

  Stream<List<Paiement>> getPaiementsEtudiant(String etudiantId) {
    return _firestore
        .collection(AppConstants.paiementsCollection)
        .where('etudiantId', isEqualTo: etudiantId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Paiement.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  Stream<List<Paiement>> getAllPaiements() {
    return _firestore
        .collection(AppConstants.paiementsCollection)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Paiement.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<Paiement>> getPaiementsEnAttente() {
    return _firestore
        .collection(AppConstants.paiementsCollection)
        .where('statut', isEqualTo: 'en_attente')
        .snapshots()
        .map((snapshot) {
          final paiements = snapshot.docs
              .map((doc) => Paiement.fromFirestore(doc.data(), doc.id))
              .toList();
          paiements.sort((a, b) => b.date.compareTo(a.date));
          return paiements;
        });
  }

  Stream<List<Recu>> getRecusEtudiant(String etudiantId) {
    return _firestore
        .collection(AppConstants.recusCollection)
        .where('etudiantId', isEqualTo: etudiantId)
        .orderBy('dateGeneration', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Recu.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<Recu>> getAllRecus() {
    return _firestore
        .collection(AppConstants.recusCollection)
        .orderBy('dateGeneration', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Recu.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  Future<AdminDashboardStats> getAdminDashboardStats() async {
    final users = await _firestore
        .collection(AppConstants.usersCollection)
        .get();
    final etudiants = await _firestore
        .collection(AppConstants.etudiantsCollection)
        .get();
    final inscriptions = await _firestore
        .collection(AppConstants.inscriptionsCollection)
        .where('statut', isEqualTo: 'active')
        .get();
    final paiements = await _firestore
        .collection(AppConstants.paiementsCollection)
        .where('statut', isEqualTo: 'valide')
        .get();

    return AdminDashboardStats(
      utilisateurs: users.size,
      etudiants: etudiants.size,
      inscriptionsActives: inscriptions.size,
      paiementsValides: paiements.size,
    );
  }

  Future<Map<String, double>> getRapportFinancierGlobal() async {
    final inscriptions = await _firestore
        .collection(AppConstants.inscriptionsCollection)
        .where('statut', isEqualTo: 'active')
        .get();
    final paiements = await _firestore
        .collection(AppConstants.paiementsCollection)
        .where('statut', isEqualTo: 'valide')
        .get();
    final echeances = await _firestore
        .collection(AppConstants.echeancesCollection)
        .get();

    final totalFrais = inscriptions.docs.fold<double>(
      0,
      (acc, doc) => acc + ((doc.data()['fraisTotal'] ?? 0) as num).toDouble(),
    );
    final totalPaye = paiements.docs.fold<double>(
      0,
      (acc, doc) => acc + ((doc.data()['montant'] ?? 0) as num).toDouble(),
    );
    final totalRetard = echeances.docs
        .map((doc) => Echeance.fromFirestore(doc.data(), doc.id))
        .where((e) => e.statut == StatutEcheance.retard)
        .fold<double>(
          0,
          (acc, e) => acc + e.montantRestant.clamp(0, e.montant),
        );

    return <String, double>{
      'totalFrais': totalFrais,
      'totalPaye': totalPaye,
      'soldeGlobal': totalFrais - totalPaye,
      'totalRetard': totalRetard,
    };
  }

  Stream<List<Filiere>> getFilieres() {
    return _firestore
        .collection(AppConstants.filieresCollection)
        .orderBy('nom')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Filiere.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> saveFiliere(Filiere filiere) async {
    await _firestore
        .collection(AppConstants.filieresCollection)
        .doc(filiere.id)
        .set(filiere.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteFiliere(String filiereId) async {
    await _firestore
        .collection(AppConstants.filieresCollection)
        .doc(filiereId)
        .delete();
  }

  Stream<List<AnneeAcademique>> getAnneesAcademiques() {
    return _firestore
        .collection(AppConstants.anneesAcademiquesCollection)
        .orderBy('dateDebut', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AnneeAcademique.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> saveAnneeAcademique(AnneeAcademique annee) async {
    await _firestore
        .collection(AppConstants.anneesAcademiquesCollection)
        .doc(annee.id)
        .set(annee.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteAnneeAcademique(String anneeId) async {
    await _firestore
        .collection(AppConstants.anneesAcademiquesCollection)
        .doc(anneeId)
        .delete();
  }

  // ============ RAW GETTERS (FUTURE) ============
  Future<Paiement?> getRawPaiement(String id) async {
    final doc = await _firestore.collection(AppConstants.paiementsCollection).doc(id).get();
    if (!doc.exists) return null;
    return Paiement.fromFirestore(doc.data()!, doc.id);
  }

  Future<Etudiant?> getRawEtudiant(String id) async {
    final doc = await _firestore.collection(AppConstants.etudiantsCollection).doc(id).get();
    if (!doc.exists) return null;
    return Etudiant.fromFirestore(doc.data()!, doc.id);
  }

  Future<Inscription?> getRawInscription(String id) async {
    final doc = await _firestore.collection(AppConstants.inscriptionsCollection).doc(id).get();
    if (!doc.exists) return null;
    return Inscription.fromFirestore(doc.data()!, doc.id);
  }
}
