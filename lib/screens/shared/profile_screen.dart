import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../models/user/etudiant.dart';
import '../../models/user/user.dart';
import '../../providers/etudiant_provider.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _matriculeController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  late String _niveauSouhaite;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _matriculeController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUtilisateurProvider);
    final etudiantAsync = ref.watch(currentEtudiantProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Aucun utilisateur connecté.'));
          }

          return etudiantAsync.when(
            data: (etudiant) {
              _initControllers(user, etudiant);
              return _buildForm(user, etudiant);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('$error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
      ),
    );
  }

  void _initControllers(Utilisateur user, Etudiant? etudiant) {
    if (_initialized) {
      return;
    }
    _nomController.text = user.nom;
    _prenomController.text = user.prenom;
    _matriculeController.text = etudiant?.matricule ?? '';
    _telephoneController.text = etudiant?.telephone ?? '';
    _adresseController.text = etudiant?.adresse ?? '';
    _niveauSouhaite = etudiant?.niveau ?? AppConstants.niveaux.first;
    _initialized = true;
  }

  Widget _buildForm(Utilisateur user, Etudiant? etudiant) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          TextFormField(
            initialValue: user.email,
            enabled: false,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _prenomController,
            decoration: const InputDecoration(labelText: 'Prénom'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nomController,
            decoration: const InputDecoration(labelText: 'Nom'),
            validator: _required,
          ),
          if (etudiant != null) ...<Widget>[
            const SizedBox(height: 12),
            TextFormField(
              controller: _matriculeController,
              decoration: const InputDecoration(labelText: 'Matricule'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telephoneController,
              decoration: const InputDecoration(labelText: 'Téléphone'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _adresseController,
              decoration: const InputDecoration(labelText: 'Adresse'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _niveauSouhaite,
              items: AppConstants.niveaux
                  .map(
                    (niveau) => DropdownMenuItem<String>(
                      value: niveau,
                      child: Text(niveau),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _niveauSouhaite = value;
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Niveau souhaité'),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSaving ? null : () => _save(user, etudiant),
            child: Text(_isSaving ? 'Enregistrement...' : 'Mettre à jour'),
          ),
        ],
      ),
    );
  }

  Future<void> _save(Utilisateur user, Etudiant? etudiant) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);

    try {
      if (etudiant != null) {
        final etudiantUpdated = etudiant.copyWith(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          matricule: _matriculeController.text.trim(),
          telephone: _telephoneController.text.trim(),
          adresse: _adresseController.text.trim(),
          niveau: _niveauSouhaite,
        );
        await ref.read(profileServiceProvider).updateEtudiant(etudiantUpdated);
      } else {
        await ref.read(profileServiceProvider).updateUtilisateur(user);
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil mis à jour.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ requis';
    }
    return null;
  }
}
