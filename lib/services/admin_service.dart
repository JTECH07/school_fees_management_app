import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uatm_paiements/services/validation_service.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/status.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ValidationService _validationService = const ValidationService();

  /// Valide une inscription : génère le matricule, active l'étudiant et crée les échéances (RM3)
  Future<void> validerInscription({
    required String etudiantId,
    String? inscriptionId, // Rendu optionnel pour gérer les anciens étudiants
    required double fraisTotal,
    String? matricule,
    String? anneeAcademique,
  }) async {
    final etudiantRef = _db.collection(AppConstants.etudiantsCollection).doc(etudiantId);
    final userRef = _db.collection(AppConstants.usersCollection).doc(etudiantId);
    final counterRef = _db.collection('settings').doc('counters');

    return _db.runTransaction((transaction) async {
      // 0. Récupérer les infos de l'étudiant pour l'inscription si nécessaire
      final etudiantSnap = await transaction.get(etudiantRef);
      if (!etudiantSnap.exists) throw 'Étudiant introuvable';
      final etudiantData = etudiantSnap.data() as Map<String, dynamic>;

      String finalInscriptionId = inscriptionId ?? '';
      DocumentReference? inscriptionRef;

      if (finalInscriptionId.isEmpty) {
        // Créer une nouvelle référence d'inscription si aucune n'est fournie
        inscriptionRef = _db.collection(AppConstants.inscriptionsCollection).doc();
        finalInscriptionId = inscriptionRef.id;
      } else {
        inscriptionRef = _db.collection(AppConstants.inscriptionsCollection).doc(finalInscriptionId);
      }

      String finalMatricule = matricule ?? '';

      // 1. Obtenir le numéro de séquence actuel pour le matricule (seulement si pas de matricule fourni)
      int nextSeq = 0;
      if (finalMatricule.isEmpty) {
        DocumentSnapshot counterSnap = await transaction.get(counterRef);
        int currentSeq = 0;
        if (counterSnap.exists) {
          final data = counterSnap.data() as Map<String, dynamic>;
          currentSeq = data['student_count'] ?? 0;
        }
        nextSeq = currentSeq + 1;

        // 2. Générer le matricule (Ex: GASA-2026-001)
        String annee = DateTime.now().year.toString();
        finalMatricule = "GASA-$annee-${nextSeq.toString().padLeft(3, '0')}";
      }

      // 3. Mettre à jour l'étudiant et son compte utilisateur
      transaction.update(etudiantRef, {
        'matricule': finalMatricule,
        'statutValidation': 'valide',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(userRef, {'estActif': true});

      // 4. Créer ou mettre à jour l'inscription
      transaction.set(
        inscriptionRef,
        {
          'id': finalInscriptionId,
          'etudiantId': etudiantId,
          'filiereId': etudiantData['filiereId'] ?? 'Inconnue',
          'niveau': etudiantData['niveau'] ?? 'N/A',
          'anneeAcademique': anneeAcademique ?? '2026-2027',
          'statut': StatutInscription.active,
          'fraisTotal': fraisTotal,
          'updatedAt': FieldValue.serverTimestamp(),
          if (inscriptionId == null) 'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 5. Générer les 5 échéances via le ValidationService
      final echeances = _validationService.genererEcheances(
        inscriptionId: finalInscriptionId,
        fraisTotal: fraisTotal,
        dateReference: DateTime.now(),
        nombreEcheances: 5,
      );

      for (final ech in echeances) {
        final echeanceDoc = _db.collection(AppConstants.echeancesCollection).doc();
        transaction.set(echeanceDoc, {
          ...ech.toFirestore(),
          'id': echeanceDoc.id,
          'etudiantId': etudiantId,
          'statut': StatutEcheanceValue.aPayer,
        });
      }

      // 6. Incrémenter le compteur global (seulement si utilisé)
      if (nextSeq > 0) {
        transaction.set(
          counterRef,
          {'student_count': nextSeq},
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<void> refuserInscription(String etudiantId, String motif) async {
    await _db
        .collection(AppConstants.etudiantsCollection)
        .doc(etudiantId)
        .update({'statutValidation': 'refuse', 'commentaireValidation': motif});
  }

  Future<void> ajouterAnneeAcademique(String libelle) async {
    final docRef = _db.collection('annees_academiques').doc();
    await docRef.set({
      'id': docRef.id,
      'libelle': libelle,
      'dateDebut': FieldValue.serverTimestamp(),
      'dateFin': FieldValue.serverTimestamp(), // À ajuster manuellement si besoin
      'estFermee': false,
    });
  }
}
