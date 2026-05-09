// lib/models/finance/inscription.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Inscription {
  final String id;
  final String etudiantId;
  final String filiereId;
  final String niveau;
  final String anneeAcademique;
  final String statut; // 'en_attente', 'active', 'annulee', 'terminee'
  final double fraisTotal;
  final DateTime createdAt;
  final DateTime updatedAt;

  Inscription({
    required this.id,
    required this.etudiantId,
    required this.filiereId,
    required this.niveau,
    required this.anneeAcademique,
    required this.statut,
    required this.fraisTotal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Inscription.fromFirestore(Map<String, dynamic> data, String id) {
    return Inscription(
      id: id,
      etudiantId: data['etudiantId'] as String? ?? '',
      filiereId: data['filiereId'] as String? ?? '',
      niveau: data['niveau'] as String? ?? '',
      anneeAcademique: data['anneeAcademique'] as String? ?? '',
      statut: data['statut'] as String? ?? '',
      fraisTotal: (data['fraisTotal'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'etudiantId': etudiantId,
      'filiereId': filiereId,
      'niveau': niveau,
      'anneeAcademique': anneeAcademique,
      'statut': statut,
      'fraisTotal': fraisTotal,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Inscription copyWith({
    String? id,
    String? etudiantId,
    String? filiereId,
    String? niveau,
    String? anneeAcademique,
    String? statut,
    double? fraisTotal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Inscription(
      id: id ?? this.id,
      etudiantId: etudiantId ?? this.etudiantId,
      filiereId: filiereId ?? this.filiereId,
      niveau: niveau ?? this.niveau,
      anneeAcademique: anneeAcademique ?? this.anneeAcademique,
      statut: statut ?? this.statut,
      fraisTotal: fraisTotal ?? this.fraisTotal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
