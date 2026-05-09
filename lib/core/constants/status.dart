class StatutPaiementValue {
  static const String enAttente = 'en_attente';
  static const String valide = 'valide';
  static const String refuse = 'refuse';
}

enum StatutPaiement { enAttente, valide, refuse }

class StatutEcheanceValue {
  static const String aPayer = 'a_payer';
  static const String payee = 'payee';
  static const String retard = 'retard';
}

enum StatutEcheance { aPayer, payee, retard }

class StatutInscription {
  static const String enAttente = 'en_attente';
  static const String active = 'active';
  static const String annulee = 'annulee';
  static const String terminee = 'terminee';
}

class StatutValidationEtudiant {
  static const String enAttente = 'en_attente';
  static const String valide = 'valide';
  static const String refuse = 'refuse';
}
