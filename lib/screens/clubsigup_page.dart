// Updated ClubSignUpPage to support multiple profiles per user

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/country_selector.dart';

class ClubSignUpPage extends StatefulWidget {
  final String userId;
  final String name;
  final String email;
  const ClubSignUpPage({Key? key, required this.userId, required this.name, required this.email}) : super(key: key);

  @override
  State<ClubSignUpPage> createState() => _ClubSignUpPageState();
}

class _ClubSignUpPageState extends State<ClubSignUpPage> {
  late final String name;
  late final String email;
  final _formKey = GlobalKey<FormState>();
  final _clubNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String? _selectedCountry;
  bool _isSaving = false;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    name = widget.name;
    email = widget.email;
    // Optionally, use name/email to pre-fill fields
  }

  @override
  void dispose() {
    _clubNameCtrl.dispose();
    _locationCtrl.dispose();
    _websiteCtrl.dispose();
    _descriptionCtrl.dispose();

    super.dispose();
  }

  String get _userEmail {
    final user = _supabase.auth.currentUser;
    return user?.email ?? '';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate country selection
    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un pays'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_userEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email non trouvé. Veuillez vous reconnecter.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _saveClubProfile();
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil enregistré avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la sauvegarde: \\${error.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveClubProfile() async {
    try {
      // Combine country and location
      final locationWithCountry =
          _selectedCountry != null
              ? '${_locationCtrl.text.trim()}, $_selectedCountry'
              : _locationCtrl.text.trim();

      await _supabase.from('club_profiles').insert({
        'user_id': widget.userId,
        'club_name': _clubNameCtrl.text.trim(),
        'location': locationWithCountry,
        'website':
            _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Club Sign Up',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0f0f23),
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f0f23),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildClubForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildClubForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.green[400]!, Colors.blue[400]!],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green[400]!.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.business,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Club Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete your club information',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Club Information Section
          _buildSectionTitle('Club Information'),
          const SizedBox(height: 16),

          _buildLabel('Nom du club'),
          _buildField(_clubNameCtrl, 'Entrez le nom du club'),

          _buildLabel('Pays'),
          CountrySelector(
            selectedCountry: _selectedCountry,
            onCountrySelected: (country) {
              setState(() => _selectedCountry = country);
            },
            showFlags: true,
            showPopularFirst: true,
            hintText: 'Sélectionnez le pays',
          ),

          _buildLabel('Ville / Région'),
          _buildField(_locationCtrl, 'Ex: Tunis, Sfax, Paris, Madrid...'),

          const SizedBox(height: 24),

          // Additional Information Section
          _buildSectionTitle('Additional Information'),
          const SizedBox(height: 16),

          _buildLabel('Site web (optionnel)'),
          _buildField(
            _websiteCtrl,
            'https://exemple.com',
            keyboard: TextInputType.url,
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              final uri = Uri.tryParse(v);
              if (uri == null || !uri.isAbsolute) return 'URL invalide';
              return null;
            },
          ),

          _buildLabel('Description'),
          _buildField(_descriptionCtrl, 'Décrivez votre club', maxLines: 3),

          const SizedBox(height: 32),

          // Save Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.green[600]!],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green[400]!.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isSaving
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        'Enregistrer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green[400]!.withValues(alpha: 0.2),
            Colors.blue[400]!.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[400]!.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.business_center, color: Colors.green[400], size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.green[400],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  );

  Widget _buildField(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 16,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green[400]!, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
        ),
        validator:
            validator ??
            (v) => v == null || v.isEmpty ? 'Ce champ est requis' : null,
      ),
    );
  }
}
