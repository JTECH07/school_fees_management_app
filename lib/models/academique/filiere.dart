class Filiere {
  final String id;
  final String nom;
  final String code;
  final Map<String, double> fraisParNiveau; // {"L1": 500000, "L2": 500000, ...}

  Filiere({
    required this.id,
    required this.nom,
    required this.code,
    required this.fraisParNiveau,
  });

  factory Filiere.fromFirestore(Map<String, dynamic> data, String id) {
    return Filiere(
      id: id,
      nom: data['nom'] ?? '',
      code: data['code'] ?? '',
      fraisParNiveau: Map<String, double>.from(data['fraisParNiveau'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'nom': nom, 'code': code, 'fraisParNiveau': fraisParNiveau};
  }
}
