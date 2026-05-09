import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/status.dart';

class Echeance {
  final String id;
  final String inscriptionId;
  final int numero;
  final String libelle;
  final double montant;
  final double montantPaye;
  final DateTime dateLimite;
  final StatutEcheance statut;
  final DateTime createdAt;
  final DateTime updatedAt;

  Echeance({
    required this.id,
    required this.inscriptionId,
    required this.numero,
    required this.libelle,
    required this.montant,
    required this.montantPaye,
    required this.dateLimite,
    required this.statut,
    required this.createdAt,
    required this.updatedAt,
  });

  double get montantRestant => montant - montantPaye;

  factory Echeance.fromFirestore(Map<String, dynamic> data, String id) {
    return Echeance(
      id: id,
      inscriptionId: data['inscriptionId'] as String? ?? '',
      numero: data['numero'] as int? ?? 0,
      libelle: data['libelle'] as String? ?? '',
      montant: (data['montant'] as num?)?.toDouble() ?? 0.0,
      montantPaye: (data['montantPaye'] as num?)?.toDouble() ?? 0.0,
      dateLimite: (data['dateLimite'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statut: _stringToStatutEcheance(data['statut'] as String? ?? 'a_payer'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'inscriptionId': inscriptionId,
      'numero': numero,
      'libelle': libelle,
      'montant': montant,
      'montantPaye': montantPaye,
      'dateLimite': dateLimite,
      'statut': statut.toString().split('.').last,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static StatutEcheance _stringToStatutEcheance(String statut) {
    switch (statut) {
      case 'a_payer':
        return StatutEcheance.aPayer;
      case 'payee':
        return StatutEcheance.payee;
      case 'retard':
        return StatutEcheance.retard;
      default:
        return StatutEcheance.aPayer; // Default ou erreur
    }
  }

  Echeance copyWith({
    String? id,
    String? inscriptionId,
    int? numero,
    String? libelle,
    double? montant,
    double? montantPaye,
    DateTime? dateLimite,
    StatutEcheance? statut,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Echeance(
      id: id ?? this.id,
      inscriptionId: inscriptionId ?? this.inscriptionId,
      numero: numero ?? this.numero,
      libelle: libelle ?? this.libelle,
      montant: montant ?? this.montant,
      montantPaye: montantPaye ?? this.montantPaye,
      dateLimite: dateLimite ?? this.dateLimite,
      statut: statut ?? this.statut,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
