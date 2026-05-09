import 'package:cloud_firestore/cloud_firestore.dart';

class Recu {
  final String id;
  final String paiementId;
  final String etudiantId;
  final String inscriptionId;
  final String numero;
  final double montant;
  final DateTime dateGeneration;
  final String? pdfUrl; // URL vers le PDF généré (si stocké dans le cloud)

  Recu({
    required this.id,
    required this.paiementId,
    required this.etudiantId,
    required this.inscriptionId,
    required this.numero,
    required this.montant,
    required this.dateGeneration,
    this.pdfUrl,
  });

  factory Recu.fromFirestore(Map<String, dynamic> data, String id) {
    return Recu(
      id: id,
      paiementId: data['paiementId'] as String? ?? '',
      etudiantId: data['etudiantId'] as String? ?? '',
      inscriptionId: data['inscriptionId'] as String? ?? '',
      numero: data['numero'] as String? ?? '',
      montant: (data['montant'] as num?)?.toDouble() ?? 0.0,
      dateGeneration: (data['dateGeneration'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pdfUrl: data['pdfUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'paiementId': paiementId,
      'etudiantId': etudiantId,
      'inscriptionId': inscriptionId,
      'numero': numero,
      'montant': montant,
      'dateGeneration': dateGeneration,
      'pdfUrl': pdfUrl,
    };
  }

  Recu copyWith({
    String? id,
    String? paiementId,
    String? etudiantId,
    String? inscriptionId,
    String? numero,
    double? montant,
    DateTime? dateGeneration,
    String? pdfUrl,
  }) {
    return Recu(
      id: id ?? this.id,
      paiementId: paiementId ?? this.paiementId,
      etudiantId: etudiantId ?? this.etudiantId,
      inscriptionId: inscriptionId ?? this.inscriptionId,
      numero: numero ?? this.numero,
      montant: montant ?? this.montant,
      dateGeneration: dateGeneration ?? this.dateGeneration,
      pdfUrl: pdfUrl ?? this.pdfUrl,
    );
  }
}
