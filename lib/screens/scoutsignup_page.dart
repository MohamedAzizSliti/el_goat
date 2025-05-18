// Updated scout signup page for multiple profiles per user
// Allows inserting multiple scout profiles for the same user

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'success_page.dart';

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

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _experienceYearsCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _selectedCountry;
  String? _selectedScoutingLevel;

  final List<String> _countries = ['Tunisia', 'Algeria', 'Morocco'];
  final List<String> _scoutingLevels = ['Local', 'National', 'International'];

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _experienceYearsCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final profile = {
        'user_id': widget.userId,
        'full_name': _fullNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'country': _selectedCountry,
        'city': _cityCtrl.text.trim(),
        'scouting_level': _selectedScoutingLevel,
        'years_experience': int.parse(_experienceYearsCtrl.text.trim()),
        'bio': _bioCtrl.text.trim(),
        'last_seen': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('scout_profiles')
          .insert(profile);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuccessPage()),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}'), backgroundColor: Colors.red),
        );
        debugPrint('Supabase error: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(text, style: TextStyle(color: Colors.grey[300], fontWeight: FontWeight.w500)),
      );

  Widget _buildTextField(String hint, TextEditingController controller, {TextInputType keyboard = TextInputType.text, String? Function(String?)? validator}) =>
      TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboard,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[800],
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
      );

  Widget _buildDropdown(List<String> items, String? value, void Function(String?) onChanged) =>
      DropdownButtonFormField<String>(
        value: value,
        dropdownColor: Colors.grey[900],
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Complete Scout Profile',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('Full Name'),
                  _buildTextField('Enter your full name', _fullNameCtrl),
                  _buildLabel('Phone Number'),
                  _buildTextField(
                    'Enter phone',
                    _phoneCtrl,
                    keyboard: TextInputType.phone,
                    validator: (v) {
                      final val = v!.trim();
                      if (!RegExp(r'^\d{8,15}\$').hasMatch(val)) {
                        return 'Enter 8–15 digits';
                      }
                      return null;
                    },
                  ),
                  _buildLabel('Country'),
                  _buildDropdown(_countries, _selectedCountry, (val) => setState(() => _selectedCountry = val)),
                  _buildLabel('City'),
                  _buildTextField('Enter your city', _cityCtrl),
                  _buildLabel('Scouting Level'),
                  _buildDropdown(_scoutingLevels, _selectedScoutingLevel, (val) => setState(() => _selectedScoutingLevel = val)),
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
                      hintText: 'Write a short bio...'
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save & Continue', style: TextStyle(color: Colors.white, fontSize: 18)),
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