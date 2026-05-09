import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/status.dart';
import '../models/finance/paiement.dart';
import '../models/finance/echeance.dart';
import 'validation_service.dart';

class PaiementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ValidationService _validationService = const ValidationService();

  /// Méthode utilisée par la Secrétaire pour enregistrer directement un paiement
  /// (crée le paiement en statut "en_attente" prêt pour validation)
  Future<bool> enregistrerPaiementParSecretaire({
    required String inscriptionId,
    required String etudiantId,
    required String secretaireId,
    required double montant,
    required String mode,
    String? referencePaiement,
    String? note,
  }) async {
    try {
      final validationError = _validationService.validerMontantPaiement(
        montant,
      );
      if (validationError != null) return false;

      DocumentReference<Map<String, dynamic>> paiementRef = _firestore
          .collection(AppConstants.paiementsCollection)
          .doc();
      await paiementRef.set({
        'id': paiementRef.id,
        'inscriptionId': inscriptionId,
        'etudiantId': etudiantId,
        'secretaireId': secretaireId, // La secrétaire initie le paiement
        'montant': montant,
        'mode': mode,
        'date': FieldValue.serverTimestamp(),
        'note': note,
        'referencePaiement': referencePaiement,
        'statut': StatutPaiementValue.enAttente,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> demanderPaiement({
    required String inscriptionId,
    required String etudiantId,
    required double montant,
    required String mode,
    String? referencePaiement,
    String? note,
  }) async {
    try {
      final validationError = _validationService.validerMontantPaiement(
        montant,
      );
      if (validationError != null) {
        return false;
      }

      final inscriptionQuery = await _firestore
          .collection(AppConstants.inscriptionsCollection)
          .where(FieldPath.documentId, isEqualTo: inscriptionId)
          .where('etudiantId', isEqualTo: etudiantId)
          .where('statut', isEqualTo: StatutInscription.active)
          .limit(1)
          .get();

      if (inscriptionQuery.docs.isEmpty) {
        return false;
      }

      // 1. Créer le document paiement
      DocumentReference<Map<String, dynamic>> paiementRef = _firestore
          .collection(AppConstants.paiementsCollection)
          .doc();

      await paiementRef.set({
        'id': paiementRef.id,
        'inscriptionId': inscriptionId,
        'etudiantId': etudiantId,
        'secretaireId':
            null, // Pas de secrétaire associée à une demande étudiante
        'montant': montant,
        'mode': mode,
        'date': FieldValue.serverTimestamp(),
        'note': note,
        'referencePaiement': referencePaiement,
        'statut': StatutPaiementValue.enAttente,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Simule un paiement Mobile Money "réel" (avec validation automatique)
  Future<bool> effectuerPaiementMobileMoney({
    required String inscriptionId,
    required String etudiantId,
    required double montant,
    required String telephone,
    String? note,
  }) async {
    try {
      // 1. Simuler un délai de traitement réseau/passerelle (2-3 secondes)
      await Future.delayed(const Duration(seconds: 3));

      // 2. Validation du montant via le service de validation
      final validationError = _validationService.validerMontantPaiement(montant);
      if (validationError != null) return false;

      // 3. Création du paiement déjà VALIDÉ (puisque le paiement "réel" a réussi)
      final DocumentReference<Map<String, dynamic>> paiementRef =
          _firestore.collection(AppConstants.paiementsCollection).doc();

      final String paiementId = paiementRef.id;

      await _firestore.runTransaction((transaction) async {
        // Enregistrer le paiement comme validé
        transaction.set(paiementRef, {
          'id': paiementId,
          'inscriptionId': inscriptionId,
          'etudiantId': etudiantId,
          'secretaireId': 'SYSTEM_GATEWAY', // Marqué comme validé par le système
          'montant': montant,
          'mode': ModePaiement.mobileMoney.toString().split('.').last,
          'date': FieldValue.serverTimestamp(),
          'note': note,
          'referencePaiement': telephone,
          'statut': StatutPaiementValue.valide,
          'createdAt': FieldValue.serverTimestamp(),
          'processedAt': FieldValue.serverTimestamp(),
        });

        // Mettre à jour les échéances
        await _mettreAJourEcheances(inscriptionId, montant, transaction);

        // Générer le reçu
        await _genererRecu(
          paiementId: paiementId,
          etudiantId: etudiantId,
          inscriptionId: inscriptionId,
          montant: montant,
          transaction: transaction,
        );
      });

      return true;
    } catch (e) {
      print('Erreur paiement Mobile Money: $e');
      return false;
    }
  }

  Future<bool> validerPaiement({
    required String paiementId,
    required String secretaireId,
  }) async {
    try {
      final paiementSnapshot = await _firestore
          .collection(AppConstants.paiementsCollection)
          .doc(paiementId)
          .get();
      if (!paiementSnapshot.exists) {
        return false;
      }

      final paiement = Paiement.fromFirestore(
        paiementSnapshot.data()!,
        paiementSnapshot.id,
      );
      if (paiement.statut != StatutPaiement.enAttente) {
        return false;
      }

      await _firestore.runTransaction((transaction) async {
        transaction.update(paiementSnapshot.reference, <String, dynamic>{
          'secretaireId': secretaireId,
          'statut': StatutPaiementValue.valide,
          'motifRefus': null,
          'processedAt': FieldValue.serverTimestamp(),
        });

        await _mettreAJourEcheances(
          paiement.inscriptionId,
          paiement.montant,
          transaction,
        );
        await _genererRecu(
          paiementId: paiement.id,
          etudiantId: paiement.etudiantId,
          inscriptionId: paiement.inscriptionId,
          montant: paiement.montant,
          transaction: transaction,
        );
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> refuserPaiement({
    required String paiementId,
    required String secretaireId,
    required String motifRefus,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.paiementsCollection)
          .doc(paiementId)
          .update(<String, dynamic>{
            'secretaireId': secretaireId,
            'statut': StatutPaiementValue.refuse,
            'motifRefus': motifRefus,
            'processedAt': FieldValue.serverTimestamp(),
          });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Calculer le solde d'un étudiant (RM10)
  Future<double> getSoldeEtudiant(String etudiantId) async {
    // Récupérer l'inscription active
    QuerySnapshot inscriptionQuery = await _firestore
        .collection(AppConstants.inscriptionsCollection)
        .where('etudiantId', isEqualTo: etudiantId)
        .where('statut', isEqualTo: StatutInscription.active)
        .limit(1)
        .get();

    if (inscriptionQuery.docs.isEmpty) return 0.0;

    double fraisTotal = inscriptionQuery.docs.first['fraisTotal'];

    // Récupérer total des paiements validés
    QuerySnapshot paiementsQuery = await _firestore
        .collection(AppConstants.paiementsCollection)
        .where('etudiantId', isEqualTo: etudiantId)
        .where('statut', isEqualTo: StatutPaiementValue.valide)
        .get();

    double totalPaye = 0.0;
    for (var doc in paiementsQuery.docs) {
      totalPaye += doc['montant'];
    }

    return fraisTotal - totalPaye;
  }

  // Mise à jour des échéances après paiement
  Future<void> _mettreAJourEcheances(
    String inscriptionId,
    double montantPaye,
    Transaction transaction,
  ) async {
    // Correction : Utiliser une requête classique pour obtenir les documents,
    // car transaction.get n'accepte que des DocumentReference.
    final QuerySnapshot<Map<String, dynamic>> echeancesQuery = await _firestore
        .collection(AppConstants.echeancesCollection)
        .where('inscriptionId', isEqualTo: inscriptionId)
        .orderBy('numero')
        .get();

    final List<Echeance> echeances = echeancesQuery.docs
        .map((doc) => Echeance.fromFirestore(doc.data(), doc.id))
        .toList();
    final List<Echeance> updated = _validationService
        .appliquerPaiementAuxEcheances(
          echeances: echeances,
          montantPaye: montantPaye,
        );

    for (int index = 0; index < updated.length; index++) {
      final Echeance echeance = updated[index];
      transaction
          .update(echeancesQuery.docs[index].reference, <String, dynamic>{
            'montantPaye': echeance.montantPaye,
            'statut': _mapStatutEcheance(echeance.statut),
          });
    }
  }

  Future<void> _genererRecu({
    required String paiementId,
    required String etudiantId,
    required String inscriptionId,
    required double montant,
    required Transaction transaction,
  }) async {
    // Générer un numéro de reçu unique
    String recuNumber =
        'REC-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch}';

    transaction.set(_firestore.collection(AppConstants.recusCollection).doc(), {
      // Utilisation de set pour créer le document avec un ID généré
      'paiementId': paiementId,
      'etudiantId': etudiantId,
      'inscriptionId': inscriptionId,
      'numero': recuNumber,
      'montant': montant,
      'dateGeneration': FieldValue.serverTimestamp(),
    });
  }

  String _mapStatutEcheance(StatutEcheance statut) {
    switch (statut) {
      case StatutEcheance.payee:
        return StatutEcheanceValue.payee;
      case StatutEcheance.retard:
        return StatutEcheanceValue.retard;
      case StatutEcheance.aPayer:
        return StatutEcheanceValue.aPayer;
    }
  }
}
