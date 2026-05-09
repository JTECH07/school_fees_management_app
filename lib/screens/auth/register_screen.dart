import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/filiere_provider.dart';
import '../../core/constants/roles.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();

  String _selectedRole = AppRoles.etudiant;
  String? _selectedFiliereId;
  String? _selectedNiveau;
  String? _selectedAnnee;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filieresAsync = ref.watch(filieresProvider);
    final anneesAsync = ref.watch(anneesAcademiquesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Création de compte'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rejoignez UATM',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 8),
              Text(
                'Complétez vos informations pour commencer.',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 32),
              
              const Text('Quel est votre rôle ?', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                items: [
                  DropdownMenuItem(value: AppRoles.etudiant, child: Text('Étudiant')),
                  DropdownMenuItem(value: AppRoles.secretaire, child: Text('Secrétaire')),
                  DropdownMenuItem(value: AppRoles.admin, child: Text('Administrateur')),
                ],
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Informations Personnelles'),
              const SizedBox(height: 16),
              _buildTextField(_nomController, 'Nom', Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(_prenomController, 'Prénom', Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(_telephoneController, 'Téléphone', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Identifiants de connexion'),
              const SizedBox(height: 16),
              _buildTextField(_emailController, 'Email académique ou personnel', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField(_passwordController, 'Mot de passe', Icons.lock_outline, obscureText: true),
              
              if (_selectedRole == AppRoles.etudiant) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Cursus académique'),
                const SizedBox(height: 16),
                filieresAsync.when(
                  data: (filieres) => DropdownButtonFormField<String>(
                    value: _selectedFiliereId,
                    decoration: InputDecoration(
                      labelText: 'Filière',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.school_outlined),
                    ),
                    items: filieres.map((f) => DropdownMenuItem(value: f.id, child: Text(f.nom))).toList(),
                    onChanged: (v) => setState(() => _selectedFiliereId = v),
                    validator: (v) => v == null ? 'Sélectionnez une filière' : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Erreur chargement filières: $e'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedNiveau,
                  decoration: InputDecoration(
                    labelText: 'Niveau d\'études',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.trending_up),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'L1', child: Text('Licence 1')),
                    DropdownMenuItem(value: 'L2', child: Text('Licence 2')),
                    DropdownMenuItem(value: 'L3', child: Text('Licence 3')),
                    DropdownMenuItem(value: 'M1', child: Text('Master 1')),
                    DropdownMenuItem(value: 'M2', child: Text('Master 2')),
                  ],
                  onChanged: (v) => setState(() => _selectedNiveau = v),
                  validator: (v) => v == null ? 'Sélectionnez un niveau' : null,
                ),
                const SizedBox(height: 16),
                anneesAsync.when(
                  data: (annees) => DropdownButtonFormField<String>(
                    value: _selectedAnnee,
                    decoration: InputDecoration(
                      labelText: 'Année académique',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    items: annees.where((a) => !a.estFermee).map((a) => DropdownMenuItem(value: a.libelle, child: Text(a.libelle))).toList(),
                    onChanged: (v) => setState(() => _selectedAnnee = v),
                    validator: (v) => v == null ? 'Sélectionnez une année' : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Erreur: $e'),
                ),
              ],
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Créer mon compte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Déjà inscrit ?'),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.2),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        prefixIcon: Icon(icon),
      ),
      validator: (v) => v?.isEmpty ?? true ? 'Ce champ est requis' : null,
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);

      final result = await authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        role: _selectedRole,
        filiereId: _selectedRole == AppRoles.etudiant ? _selectedFiliereId : null,
        niveau: _selectedRole == AppRoles.etudiant ? _selectedNiveau : null,
        anneeAcademique: _selectedRole == AppRoles.etudiant ? _selectedAnnee : null,
      );

      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compte créé avec succès ! En attente de validation par l\'administration.'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${result.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Une erreur est survenue: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
