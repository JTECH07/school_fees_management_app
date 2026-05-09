import 'package:uatm_paiements/models/finance/paiement.dart';

import '../models/finance/echeance.dart';
import '../core/constants/status.dart';

class ValidationService {
  const ValidationService();

  String? validerMontantPaiement(double montant) {
    if (montant <= 0) {
      return 'Le montant du paiement doit être positif.';
    }
    return null;
  }

  /// Génère une liste d'échéances pour une inscription donnée.
  List<Echeance> genererEcheances({
    required String inscriptionId,
    required double fraisTotal,
    required DateTime dateReference,
    int nombreEcheances = 5,
  }) {
    final List<Echeance> echeances = [];
    final double montantParEcheance = fraisTotal / nombreEcheances;

    for (int i = 1; i <= nombreEcheances; i++) {
      echeances.add(
        Echeance(
          id: '', // Sera défini par Firestore
          inscriptionId: inscriptionId,
          numero: i,
          libelle: 'Échéance n°$i',
          montant: montantParEcheance,
          montantPaye: 0.0,
          dateLimite: dateReference.add(Duration(days: 30 * i)),
          statut: StatutEcheance.aPayer,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
    return echeances;
  }

  /// Applique un montant payé aux échéances, en les marquant comme payées ou partiellement payées.
  List<Echeance> appliquerPaiementAuxEcheances({
    required List<Echeance> echeances,
    required double montantPaye,
  }) {
    double montantRestantAPayer = montantPaye;
    final List<Echeance> updatedEcheances = List.from(echeances);

    for (int i = 0; i < updatedEcheances.length; i++) {
      Echeance echeance = updatedEcheances[i];
      if (echeance.statut != StatutEcheance.payee) {
        double aPayerSurCetteEcheance = echeance.montant - echeance.montantPaye;

        if (montantRestantAPayer >= aPayerSurCetteEcheance) {
          echeance = echeance.copyWith(
            montantPaye: echeance.montant,
            statut: StatutEcheance.payee,
            updatedAt: DateTime.now(),
          );
          montantRestantAPayer -= aPayerSurCetteEcheance;
        } else if (montantRestantAPayer > 0) {
          echeance = echeance.copyWith(
            montantPaye: echeance.montantPaye + montantRestantAPayer,
            statut: StatutEcheance.aPayer,
            updatedAt: DateTime.now(),
          );
          montantRestantAPayer = 0;
        }
        updatedEcheances[i] = echeance;
      }
      if (montantRestantAPayer <= 0) break;
    }

    // Mettre à jour le statut pour les échéances en retard
    final now = DateTime.now();
    for (int i = 0; i < updatedEcheances.length; i++) {
      Echeance echeance = updatedEcheances[i];
      if (echeance.statut == StatutEcheance.aPayer &&
          echeance.dateLimite.isBefore(now)) {
        updatedEcheances[i] = echeance.copyWith(
          statut: StatutEcheance.retard,
          updatedAt: DateTime.now(),
        );
      }
    }
    return updatedEcheances;
  }

  calculerSolde({required int fraisTotal, required List<Paiement> paiements}) {}
}
