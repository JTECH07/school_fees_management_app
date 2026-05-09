import 'package:cloud_firestore/cloud_firestore.dart';

class AnneeAcademique {
  final String id;
  final String libelle;
  final DateTime dateDebut;
  final DateTime dateFin;
  final bool estFermee;

  AnneeAcademique({
    required this.id,
    required this.libelle,
    required this.dateDebut,
    required this.dateFin,
    this.estFermee = false,
  });

  factory AnneeAcademique.fromFirestore(Map<String, dynamic> data, String id) {
    return AnneeAcademique(
      id: id,
      libelle: data['libelle'] ?? '',
      dateDebut: (data['dateDebut'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateFin: (data['dateFin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estFermee: data['estFermee'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'libelle': libelle,
      'dateDebut': Timestamp.fromDate(dateDebut),
      'dateFin': Timestamp.fromDate(dateFin),
      'estFermee': estFermee,
    };
  }
}
