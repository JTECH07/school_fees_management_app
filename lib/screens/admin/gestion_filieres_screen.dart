// lib/screens/admin/gestion_filieres_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/academique/filiere.dart';
import '../../providers/etudiant_provider.dart'; // Pour firestoreServiceProvider
import '../../core/constants/app_constants.dart';

final filieresProvider = StreamProvider<List<Filiere>>((ref) {
  return ref.watch(firestoreServiceProvider).getFilieres();
});

class GestionFilieresScreen extends ConsumerStatefulWidget {
  const GestionFilieresScreen({super.key});

  @override
  ConsumerState<GestionFilieresScreen> createState() =>
      _GestionFilieresScreenState();
}

class _GestionFilieresScreenState extends ConsumerState<GestionFilieresScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _codeController = TextEditingController();
  final Map<String, TextEditingController> _fraisControllers = {};

  Filiere? _filiereSelectionnee;

  @override
  void initState() {
    super.initState();
    for (final niveau in AppConstants.niveaux) {
      _fraisControllers[niveau] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _codeController.dispose();
    _fraisControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _nomController.clear();
      _codeController.clear();
      _fraisControllers.forEach((key, controller) => controller.clear());
      _filiereSelectionnee = null;
    });
  }

  void _chargerFiliere(Filiere filiere) {
    setState(() {
      _filiereSelectionnee = filiere;
      _nomController.text = filiere.nom;
      _codeController.text = filiere.code;
      for (final niveau in AppConstants.niveaux) {
        _fraisControllers[niveau]?.text =
            filiere.fraisParNiveau[niveau]?.toString() ?? '';
      }
    });
  }

  Future<void> _saveFiliere() async {
    if (!_formKey.currentState!.validate()) return;

    final Map<String, double> fraisParNiveau = {};
    for (final niveau in AppConstants.niveaux) {
      final montant = double.tryParse(_fraisControllers[niveau]?.text ?? '');
      if (montant != null && montant > 0) {
        fraisParNiveau[niveau] = montant;
      }
    }

    final newFiliere = Filiere(
      id:
          _filiereSelectionnee?.id ??
          ref
              .read(firestoreServiceProvider)
              .firestore
              .collection(AppConstants.filieresCollection)
              .doc()
              .id,
      nom: _nomController.text,
      code: _codeController.text,
      fraisParNiveau: fraisParNiveau,
    );

    try {
      await ref.read(firestoreServiceProvider).saveFiliere(newFiliere);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _filiereSelectionnee == null
                  ? 'Filière ajoutée !'
                  : 'Filière mise à jour !',
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

  Future<void> _deleteFiliere(String filiereId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la filière ?'),
        content: const Text(
          'Cette action est irréversible. Êtes-vous sûr de vouloir supprimer cette filière ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(firestoreServiceProvider).deleteFiliere(filiereId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Filière supprimée !')));
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
  }

  @override
  Widget build(BuildContext context) {
    final filieresAsync = ref.watch(filieresProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des Filières')),
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
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la filière',
                      ),
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Code de la filière',
                      ),
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Frais de scolarité par niveau (FCFA)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    ...AppConstants.niveaux.map(
                      (niveau) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextFormField(
                          controller: _fraisControllers[niveau],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Frais ${niveau}',
                            suffixText: 'FCFA',
                          ),
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                double.tryParse(value) == null) {
                              return 'Montant invalide';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveFiliere,
                      child: Text(
                        _filiereSelectionnee == null ? 'Ajouter' : 'Modifier',
                      ),
                    ),
                    if (_filiereSelectionnee != null)
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
              child: filieresAsync.when(
                data: (filieres) {
                  if (filieres.isEmpty) {
                    return const Center(child: Text('Aucune filière.'));
                  }
                  return ListView.builder(
                    itemCount: filieres.length,
                    itemBuilder: (context, index) {
                      final filiere = filieres[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('${filiere.nom} (${filiere.code})'),
                          subtitle: Text(
                            'Frais L1: ${filiere.fraisParNiveau['L1'] ?? 'N/A'} FCFA',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _chargerFiliere(filiere),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteFiliere(filiere.id),
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
