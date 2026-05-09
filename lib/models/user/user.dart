// lib/models/user/user.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Utilisateur {
  final String uid;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final String role;
  final bool estActif;
  final DateTime createdAt;
  final DateTime updatedAt;

  Utilisateur({
    required this.uid,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.role,
    required this.estActif,
    required this.createdAt,
    required this.updatedAt,
  });
  String get nomComplet => '$prenom $nom';

  factory Utilisateur.fromMap(Map<String, dynamic> data) {
    return Utilisateur(
      uid: data['uid'] as String? ?? '',
      email: data['email'] as String? ?? '',
      nom: data['nom'] as String? ?? '',
      prenom: data['prenom'] as String? ?? '',
      telephone: data['telephone'] as String? ?? '',
      role: data['role'] as String? ?? '',
      estActif: data['estActif'] as bool? ?? false,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory Utilisateur.fromFirestore(Map<String, dynamic> data, String uid) {
    return Utilisateur(
      uid: uid,
      email: data['email'] as String? ?? '',
      nom: data['nom'] as String? ?? '',
      prenom: data['prenom'] as String? ?? '',
      telephone: data['telephone'] as String? ?? '',
      role: data['role'] as String? ?? '',
      estActif: data['estActif'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'role': role,
      'estActif': estActif,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
