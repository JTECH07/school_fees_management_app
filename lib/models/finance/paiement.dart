import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/status.dart';

enum ModePaiement { mobileMoney, especes, virement, carte }

class Paiement {
  final String id;
  final String inscriptionId;
  final String etudiantId;
  final String? secretaireId;
  final double montant;
  final ModePaiement mode;
  final DateTime date;
  final String? note;
  final String? referencePaiement; // Nouveau champ pour téléphone/transaction MM
  final StatutPaiement statut;
  final String? motifRefus;
  final DateTime createdAt;
  final DateTime? processedAt;

  Paiement({
    required this.id,
    required this.inscriptionId,
    required this.etudiantId,
    this.secretaireId,
    required this.montant,
    required this.mode,
    required this.date,
    this.note,
    this.referencePaiement,
    required this.statut,
    this.motifRefus,
    required this.createdAt,
    this.processedAt,
  });

  factory Paiement.fromFirestore(Map<String, dynamic> data, String id) {
    return Paiement(
      id: id,
      inscriptionId: data['inscriptionId'] as String? ?? '',
      etudiantId: data['etudiantId'] as String? ?? '',
      secretaireId: data['secretaireId'] as String?,
      montant: (data['montant'] as num?)?.toDouble() ?? 0.0,
      mode: _stringToModePaiement(data['mode'] as String? ?? ''),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] as String?,
      referencePaiement: data['referencePaiement'] as String?,
      statut: _stringToStatutPaiement(data['statut'] as String? ?? ''),
      motifRefus: data['motifRefus'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'inscriptionId': inscriptionId,
      'etudiantId': etudiantId,
      'secretaireId': secretaireId,
      'montant': montant,
      'mode': mode.toString().split('.').last,
      'date': date,
      'note': note,
      'referencePaiement': referencePaiement,
      'statut': statut.toString().split('.').last,
      'motifRefus': motifRefus,
      'createdAt': createdAt,
      'processedAt': processedAt,
    };
  }

  static ModePaiement _stringToModePaiement(String mode) {
    switch (mode) {
      case 'mobileMoney':
        return ModePaiement.mobileMoney;
      case 'especes':
        return ModePaiement.especes;
      case 'virement':
        return ModePaiement.virement;
      case 'carte':
        return ModePaiement.carte;
      default:
        return ModePaiement.especes; // Default ou erreur
    }
  }

  static StatutPaiement _stringToStatutPaiement(String statut) {
    switch (statut) {
      case 'en_attente':
        return StatutPaiement.enAttente;
      case 'valide':
        return StatutPaiement.valide;
      case 'refuse':
        return StatutPaiement.refuse;
      default:
        return StatutPaiement.enAttente; // Default ou erreur
    }
  }

  Paiement copyWith({
    String? id,
    String? inscriptionId,
    String? etudiantId,
    String? secretaireId,
    double? montant,
    ModePaiement? mode,
    DateTime? date,
    String? note,
    String? referencePaiement,
    StatutPaiement? statut,
    String? motifRefus,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return Paiement(
      id: id ?? this.id,
      inscriptionId: inscriptionId ?? this.inscriptionId,
      etudiantId: etudiantId ?? this.etudiantId,
      secretaireId: secretaireId ?? this.secretaireId,
      montant: montant ?? this.montant,
      mode: mode ?? this.mode,
      date: date ?? this.date,
      note: note ?? this.note,
      referencePaiement: referencePaiement ?? this.referencePaiement,
      statut: statut ?? this.statut,
      motifRefus: motifRefus ?? this.motifRefus,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}
