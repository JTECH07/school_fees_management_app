import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uatm_paiements/core/constants/app_constants.dart';
import 'package:uatm_paiements/providers/user_provider.dart';
import '../../models/user/user.dart';
import '../../providers/etudiant_provider.dart'; // Pour firestoreServiceProvider
import '../../core/constants/roles.dart';

class GestionUtilisateursScreen extends ConsumerStatefulWidget {
  const GestionUtilisateursScreen({super.key});

  @override
  ConsumerState<GestionUtilisateursScreen> createState() =>
      _GestionUtilisateursScreenState();
}

class _GestionUtilisateursScreenState
    extends ConsumerState<GestionUtilisateursScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  String _selectedRole = AppRoles.etudiant;
  bool _estActif = true;
  Utilisateur? _utilisateurSelectionne;

  @override
  void dispose() {
    _emailController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _emailController.clear();
      _nomController.clear();
      _prenomController.clear();
      _telephoneController.clear();
      _selectedRole = AppRoles.etudiant;
      _estActif = true;
      _utilisateurSelectionne = null;
    });
  }

  void _chargerUtilisateur(Utilisateur user) {
    setState(() {
      _utilisateurSelectionne = user;
      _emailController.text = user.email;
      _nomController.text = user.nom;
      _prenomController.text = user.prenom;
      _telephoneController.text = user.telephone;
      _selectedRole = user.role;
      _estActif = user.estActif;
    });
  }

  Future<void> _saveUtilisateur() async {
    if (!_formKey.currentState!.validate()) return;

    final newUtilisateur = Utilisateur(
      uid:
          _utilisateurSelectionne?.uid ??
          ref
              .read(firestoreServiceProvider)
              .firestore
              .collection(AppConstants.usersCollection)
              .doc()
              .id,
      email: _emailController.text,
      nom: _nomController.text,
      prenom: _prenomController.text,
      telephone: _telephoneController.text,
      role: _selectedRole,
      estActif: _estActif,
      createdAt: _utilisateurSelectionne?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(firestoreServiceProvider).saveUtilisateur(newUtilisateur);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _utilisateurSelectionne == null
                  ? 'Utilisateur ajouté !'
                  : 'Utilisateur mis à jour !',
            ),
          ),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await ref
          .read(firestoreServiceProvider)
          .updateUtilisateurStatus(userId: userId, estActif: !currentStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !currentStatus
                  ? 'Utilisateur activé !'
                  : 'Utilisateur désactivé !',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final utilisateursAsync = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des Utilisateurs')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Champ requis' : null,
                    ),
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Champ requis' : null,
                    ),
                    TextFormField(
                      controller: _prenomController,
                      decoration: const InputDecoration(labelText: 'Prénom'),
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Champ requis' : null,
                    ),
                    TextFormField(
                      controller: _telephoneController,
                      decoration: const InputDecoration(labelText: 'Téléphone'),
                      keyboardType: TextInputType.phone,
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      items: AppRoles.values
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedRole = v!),
                      decoration: const InputDecoration(labelText: 'Rôle'),
                    ),
                    CheckboxListTile(
                      title: const Text('Actif'),
                      value: _estActif,
                      onChanged: (value) => setState(() => _estActif = value!),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveUtilisateur,
                      child: Text(
                        _utilisateurSelectionne == null
                            ? 'Ajouter'
                            : 'Modifier',
                      ),
                    ),
                    if (_utilisateurSelectionne != null)
                      TextButton(
                        onPressed: _resetForm,
                        child: const Text('Annuler la modification'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: utilisateursAsync.when(
                data: (utilisateurs) {
                  if (utilisateurs.isEmpty) {
                    return const Center(child: Text('Aucun utilisateur.'));
                  }
                  return ListView.builder(
                    itemCount: utilisateurs.length,
                    itemBuilder: (context, index) {
                      final user = utilisateurs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(user.nomComplet),
                          subtitle: Text('${user.email} (${user.role})'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  user.estActif
                                      ? Icons.toggle_on
                                      : Icons.toggle_off,
                                  color: user.estActif
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                onPressed: () =>
                                    _toggleUserStatus(user.uid, user.estActif),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _chargerUtilisateur(user),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    Center(child: Text('Erreur: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
