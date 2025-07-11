// Updated scout signup page for multiple profiles per user
// Allows inserting multiple scout profiles for the same user

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/country_selector.dart';
import 'dart:async';

class ScoutSignUpPage extends StatefulWidget {
  final String userId;
  final String name;
  final String email;
  const ScoutSignUpPage({
    Key? key,
    required this.userId,
    required this.name,
    required this.email,
  }) : super(key: key);

  @override
  State<ScoutSignUpPage> createState() => _ScoutSignUpPageState();
}

class _ScoutSignUpPageState extends State<ScoutSignUpPage> {
  late final String name;
  late final String email;
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
    name = widget.name;
    email = widget.email;
    _userFullName = name;
    _userEmail = email;
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
          _userFullName = widget.name;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_userEmail == null || _userEmail!.isEmpty) {
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
      await _saveScoutProfile();
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
            content: Text('Erreur lors de la sauvegarde: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveScoutProfile() async {
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

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Text(
      text,
      style: TextStyle(color: Colors.grey[300], fontWeight: FontWeight.w500),
    ),
  );

  Widget _buildTextField(
    String hint,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    style: const TextStyle(color: Colors.white),
    keyboardType: keyboard,
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.grey[800],
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
  );

  Widget _buildDropdown(
    List<String> items,
    String? value,
    void Function(String?) onChanged,
  ) => DropdownButtonFormField<String>(
    value: value,
    dropdownColor: Colors.grey[900],
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.grey[800],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    items:
        items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
    onChanged: onChanged,
    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Scout Profile'),
        centerTitle: true,
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
            child: _buildScoutForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildScoutForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Complete Scout Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Display user info from registration
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[800]?.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[600]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Information',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey[400], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Name: ${_userFullName ?? 'Loading...'}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.email, color: Colors.grey[400], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Email: ${_userEmail ?? 'Loading...'}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),

          _buildLabel('Phone Number'),
          _buildTextField(
            'Enter phone',
            _phoneCtrl,
            keyboard: TextInputType.phone,
            validator: (v) {
              final val = v!.trim();
              if (!RegExp(r'^\d{8,15}$').hasMatch(val)) {
                return 'Enter 8–15 digits';
              }
              return null;
            },
          ),
          _buildLabel('Country'),
          CountrySelector(
            selectedCountry: _selectedCountry,
            onCountrySelected: (country) {
              setState(() => _selectedCountry = country);
            },
            showFlags: true,
            showPopularFirst: true,
            hintText: 'Select your country',
          ),
          _buildLabel('City'),
          _buildTextField('Enter your city', _cityCtrl),
          _buildLabel('Scouting Level'),
          _buildDropdown(
            _scoutingLevels,
            _selectedScoutingLevel,
            (val) => setState(() => _selectedScoutingLevel = val),
          ),
          _buildLabel('Years of Experience'),
          _buildTextField(
            'Enter years',
            _experienceYearsCtrl,
            keyboard: TextInputType.number,
            validator: (v) {
              final y = int.tryParse(v!.trim());
              if (y == null || y < 0 || y > 50) {
                return '0–50 only';
              }
              return null;
            },
          ),
          _buildLabel('Bio'),
          TextFormField(
            controller: _bioCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[800],
              hintText: 'Write a short bio...',
            ),
            validator:
                (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        'Save & Continue',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
