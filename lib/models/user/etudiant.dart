// lib/models/user/etudiant.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Etudiant {
  final String id;
  final String userId;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String? matricule;
  final String? filiereId; // Filière souhaitée lors de l'inscription
  final String? niveau; // Niveau souhaité lors de l'inscription
  final String? adresse;
  final String statutValidation; // 'en_attente', 'valide', 'refuse'
  final String? commentaireValidation;
  final DateTime createdAt;
  final DateTime updatedAt;

  Etudiant({
    required this.id,
    required this.userId,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    this.matricule,
    this.filiereId,
    this.niveau,
    this.adresse,
    required this.statutValidation,
    this.commentaireValidation,
    required this.createdAt,
    required this.updatedAt,
  });

  String get nomComplet => '$prenom $nom';

  factory Etudiant.fromFirestore(Map<String, dynamic> data, String id) {
    return Etudiant(
      id: id,
      userId: data['userId'] as String? ?? '',
      nom: data['nom'] as String? ?? '',
      prenom: data['prenom'] as String? ?? '',
      email: data['email'] as String? ?? '',
      telephone: data['telephone'] as String? ?? '',
      matricule: data['matricule'] as String?,
      filiereId: data['filiereId'] as String?,
      niveau: data['niveau'] as String?,
      adresse: data['adresse'] as String?,
      statutValidation: data['statutValidation'] as String? ?? 'en_attente',
      commentaireValidation: data['commentaireValidation'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'matricule': matricule,
      'filiereId': filiereId,
      'niveau': niveau,
      'adresse': adresse,
      'statutValidation': statutValidation,
      'commentaireValidation': commentaireValidation,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Etudiant copyWith({
    String? id,
    String? userId,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? matricule,
    String? filiereId,
    String? niveau,
    String? adresse,
    String? statutValidation,
    String? commentaireValidation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Etudiant(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      matricule: matricule ?? this.matricule,
      filiereId: filiereId ?? this.filiereId,
      niveau: niveau ?? this.niveau,
      adresse: adresse ?? this.adresse,
      statutValidation: statutValidation ?? this.statutValidation,
      commentaireValidation:
          commentaireValidation ?? this.commentaireValidation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
