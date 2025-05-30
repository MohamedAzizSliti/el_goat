// Updated scout signup page for multiple profiles per user
// Allows inserting multiple scout profiles for the same user

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'success_page.dart';
import '../widgets/country_selector.dart';

class ScoutSignUpPage extends StatefulWidget {
  final String userId;
  const ScoutSignUpPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<ScoutSignUpPage> createState() => _ScoutSignUpPageState();
}

class _ScoutSignUpPageState extends State<ScoutSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  final _supabase = Supabase.instance.client;

  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _experienceYearsCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _selectedCountry;
  String? _selectedScoutingLevel;

  String? _userEmail;
  String? _userFullName;

  final List<String> _scoutingLevels = ['Local', 'National', 'International'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _experienceYearsCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        setState(() {
          _userEmail = user.email;
          _userFullName = user.userMetadata?['full_name'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final profile = {
        'user_id': widget.userId,
        'full_name': _userFullName ?? '',
        'email': _userEmail ?? '',
        'phone': _phoneCtrl.text.trim(),
        'country': _selectedCountry,
        'city': _cityCtrl.text.trim(),
        'scouting_level': _selectedScoutingLevel,
        'experience_years': int.parse(_experienceYearsCtrl.text.trim()),
        'bio': _bioCtrl.text.trim(),
        'last_seen': DateTime.now().toIso8601String(),
      };

      await _supabase.from('scout_profiles').insert(profile);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuccessPage()),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        debugPrint('Supabase error: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue[400]!.withValues(alpha: 0.2),
            Colors.purple[400]!.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[400]!.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.blue[400], size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.blue[400],
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
            borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
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

  Widget _buildModernDropdown(
    List<String> items,
    String? value,
    String hint,
    void Function(String?) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: Colors.grey[900],
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
            borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
          ),
        ),
        items:
            items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
        onChanged: onChanged,
        validator:
            (v) => (v == null || v.isEmpty) ? 'Ce champ est requis' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Scout Sign Up',
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
            child: Form(
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
                              colors: [Colors.blue[400]!, Colors.purple[400]!],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue[400]!.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.search,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Scout Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete your scout information',
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

                  // Account Information Section
                  _buildSectionTitle('Account Information'),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue[400]!.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Colors.blue[400],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Name: ${_userFullName ?? 'Loading...'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.email,
                              color: Colors.blue[400],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Email: ${_userEmail ?? 'Loading...'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Personal Information Section
                  _buildSectionTitle('Personal Information'),
                  const SizedBox(height: 16),

                  _buildLabel('Numéro de téléphone'),
                  _buildField(
                    _phoneCtrl,
                    'Entrez votre numéro de téléphone',
                    keyboard: TextInputType.phone,
                    validator: (v) {
                      final val = v!.trim();
                      if (!RegExp(r'^\d{8,15}$').hasMatch(val)) {
                        return 'Entrez 8-15 chiffres';
                      }
                      return null;
                    },
                  ),

                  _buildLabel('Pays'),
                  CountrySelector(
                    selectedCountry: _selectedCountry,
                    onCountrySelected: (country) {
                      setState(() => _selectedCountry = country);
                    },
                    showFlags: true,
                    showPopularFirst: true,
                    hintText: 'Sélectionnez votre pays',
                  ),

                  _buildLabel('Ville / Région'),
                  _buildField(_cityCtrl, 'Ex: Tunis, Sfax, Paris, Madrid...'),

                  const SizedBox(height: 24),

                  // Professional Information Section
                  _buildSectionTitle('Professional Information'),
                  const SizedBox(height: 16),

                  _buildLabel('Niveau de scouting'),
                  _buildModernDropdown(
                    _scoutingLevels,
                    _selectedScoutingLevel,
                    'Sélectionnez votre niveau',
                    (val) => setState(() => _selectedScoutingLevel = val),
                  ),

                  _buildLabel('Années d\'expérience'),
                  _buildField(
                    _experienceYearsCtrl,
                    'Entrez le nombre d\'années',
                    keyboard: TextInputType.number,
                    validator: (v) {
                      final y = int.tryParse(v!.trim());
                      if (y == null || y < 0 || y > 50) {
                        return '0-50 années seulement';
                      }
                      return null;
                    },
                  ),

                  _buildLabel('Bio / Description'),
                  _buildField(
                    _bioCtrl,
                    'Décrivez votre expérience et expertise...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue[400]!.withValues(alpha: 0.3),
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
            ),
          ),
        ),
      ),
    );
  }
}
