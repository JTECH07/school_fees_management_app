import 'package:flutter_test/flutter_test.dart';
import 'package:uatm_paiements/core/constants/status.dart';
import 'package:uatm_paiements/models/finance/paiement.dart';
import 'package:uatm_paiements/services/validation_service.dart';

void main() {
  const validationService = ValidationService();

  test('genere 5 echeances par defaut', () {
    final echeances = validationService.genererEcheances(
      inscriptionId: 'inscription-1',
      fraisTotal: 500000,
      dateReference: DateTime(2026, 1, 15),
    );

    expect(echeances, hasLength(5));
    expect(echeances.first.montant, 100000);
    expect(echeances.last.numero, 5);
  });

  test('calcule le solde a partir des paiements valides', () {
    final solde = validationService.calculerSolde(
      fraisTotal: 500000,
      paiements: <Paiement>[
        Paiement(
          id: 'p1',
          inscriptionId: 'i1',
          etudiantId: 'e1',
          secretaireId: 's1',
          montant: 100000,
          mode: ModePaiement.especes,
          date: DateTime(2026, 2, 1),
          statut: StatutPaiement.valide,
          createdAt: DateTime(2026, 2, 1),
        ),
        Paiement(
          id: 'p2',
          inscriptionId: 'i1',
          etudiantId: 'e1',
          secretaireId: 's1',
          montant: 25000,
          mode: ModePaiement.mobileMoney,
          date: DateTime(2026, 2, 15),
          statut: StatutPaiement.refuse,
          createdAt: DateTime(2026, 2, 15),
        ),
      ],
    );

    expect(solde, 400000);
  });
}
