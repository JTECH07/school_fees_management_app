import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/academique/annee_academique.dart';
import '../../models/academique/filiere.dart';
import '../../models/user/etudiant.dart';
import '../../providers/etudiant_provider.dart';
import '../../providers/filiere_provider.dart';
import '../../providers/inscription_provider.dart';
import '../../services/inscription_service.dart';

class GestionInscriptionsScreen extends ConsumerStatefulWidget {
  const GestionInscriptionsScreen({super.key});

  @override
  ConsumerState<GestionInscriptionsScreen> createState() =>
      _GestionInscriptionsScreenState();
}

class _GestionInscriptionsScreenState
    extends ConsumerState<GestionInscriptionsScreen> {
  final _formKey = GlobalKey<FormState>();
  Etudiant? _selectedEtudiant;
  Filiere? _selectedFiliere;
  AnneeAcademique? _selectedAnnee;
  String _selectedNiveau = 'L1';
  DateTime _dateInscription = DateTime.now();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final etudiantsAsync = ref.watch(allEtudiantsProvider);
    final filieresAsync = ref.watch(filieresProvider);
    final anneesAsync = ref.watch(anneesAcademiquesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Créer une inscription')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Créer une inscription génère automatiquement 5 échéances selon la filière, le niveau et l’année académique choisis.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                etudiantsAsync.when(
                  data: (etudiants) => DropdownButtonFormField<Etudiant>(
                    initialValue: _selectedEtudiant,
                    items: etudiants
                        .map(
                          (e) => DropdownMenuItem<Etudiant>(
                            value: e,
                            child: Text('${e.nomComplet} (${e.matricule})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedEtudiant = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Étudiant'),
                    validator: (value) =>
                        value == null ? 'Étudiant requis' : null,
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stackTrace) => Text('$error'),
                ),
                const SizedBox(height: 12),
                filieresAsync.when(
                  data: (filieres) => DropdownButtonFormField<Filiere>(
                    initialValue: _selectedFiliere,
                    items: filieres
                        .map(
                          (f) => DropdownMenuItem<Filiere>(
                            value: f,
                            child: Text('${f.nom} (${f.code})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFiliere = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Filière'),
                    validator: (value) =>
                        value == null ? 'Filière requise' : null,
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stackTrace) => Text('$error'),
                ),
                const SizedBox(height: 12),
                anneesAsync.when(
                  data: (annees) => DropdownButtonFormField<AnneeAcademique>(
                    initialValue: _selectedAnnee,
                    items: annees
                        .map(
                          (a) => DropdownMenuItem<AnneeAcademique>(
                            value: a,
                            child: Text(
                              '${a.libelle}${a.estFermee ? ' (fermée)' : ''}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAnnee = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Année académique',
                    ),
                    validator: (value) =>
                        value == null ? 'Année académique requise' : null,
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stackTrace) => Text('$error'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedNiveau,
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'L1', child: Text('L1')),
                    DropdownMenuItem(value: 'L2', child: Text('L2')),
                    DropdownMenuItem(value: 'L3', child: Text('L3')),
                    DropdownMenuItem(value: 'M1', child: Text('M1')),
                    DropdownMenuItem(value: 'M2', child: Text('M2')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedNiveau = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Niveau'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date d’inscription'),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy').format(_dateInscription),
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: Text(
                      _isSubmitting
                          ? 'Création en cours...'
                          : 'Créer l’inscription et les échéances',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: _dateInscription,
    );
    if (picked != null) {
      setState(() {
        _dateInscription = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(inscriptionServiceProvider)
          .creerInscription(
            etudiantId: _selectedEtudiant!.id,
            filiereId: _selectedFiliere!.id,
            niveau: _selectedNiveau,
            anneeAcademique: _selectedAnnee!.libelle,
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscription créée avec génération des échéances.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
