// lib/screens/footballersignup_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/success_page.dart';

class FootballerSignUpPage extends StatefulWidget {
  final String userId;
  const FootballerSignUpPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<FootballerSignUpPage> createState() => _FootballerSignUpPageState();
}

class _FootballerSignUpPageState extends State<FootballerSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  final _supabase = Supabase.instance.client;

  String _convertDateFormat(String dateStr) {
    final parts = dateStr.split('/');
    if (parts.length != 3) return dateStr;
    return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
  }

  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _clubCtrl = TextEditingController();

  String? position;
  String? foot;
  String? experience;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _clubCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.redAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF2C2C2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobCtrl.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final String dobFormatted = _convertDateFormat(_dobCtrl.text.trim());

      final profile = {
        'user_id': widget.userId,
        'full_name': _fullNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'dob': dobFormatted,
        'position': position,
        'preferred_foot': foot,
        'height_cm': int.parse(_heightCtrl.text.trim()),
        'weight_kg': int.parse(_weightCtrl.text.trim()),
        'experience_level': experience,
        'current_club': _clubCtrl.text.trim().isEmpty ? 'None' : _clubCtrl.text.trim(),
        'last_seen': DateTime.now().toIso8601String(),
      };

      // Insert the data allowing multiple rows
      await _supabase
          .from('footballer_profiles')
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

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          text,
          style: TextStyle(color: Colors.grey[300], fontWeight: FontWeight.w500),
        ),
      );

  Widget _buildTextField(
    String hint,
    TextEditingController ctrl, {
    TextInputType keyboard = TextInputType.text,
    IconData? prefixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboard,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[800],
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey) : null,
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
  ) =>
      DropdownButtonFormField<String>(
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
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        validator: (v) => (v == null || v.isEmpty) ? 'Please select' : null,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Complete Footballer Profile'),
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
                      'Complete Footballer Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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
                      if (!RegExp(r'^\d{8,15}$').hasMatch(val)) {
                        return 'Enter 8–15 digits';
                      }
                      return null;
                    },
                  ),
                  _buildLabel('Date of Birth'),
                  _buildTextField(
                    'DD/MM/YYYY',
                    _dobCtrl,
                    prefixIcon: Icons.calendar_today,
                    readOnly: true,
                    onTap: _selectDate,
                    validator: (v) {
                      final val = v!.trim();
                      if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(val)) {
                        return 'Use DD/MM/YYYY';
                      }
                      final parts = val.split('/');
                      final iso = '${parts[2]}-${parts[1].padLeft(2,'0')}-${parts[0].padLeft(2,'0')}';
                      final date = DateTime.tryParse(iso);
                      if (date == null) return 'Invalid date';
                      final age = DateTime.now().difference(date).inDays ~/ 365;
                      if (age < 10 || age > 80) return 'Age 10–80 only';
                      return null;
                    },
                  ),
                  _buildLabel('Position'),
                  _buildDropdown(['Goalkeeper', 'Defender', 'Midfielder', 'Striker'], position,
                      (val) => setState(() => position = val)),
                  _buildLabel('Preferred Foot'),
                  _buildDropdown(['Left', 'Right', 'Both'], foot, (val) => setState(() => foot = val)),
                  _buildLabel('Height (cm)'),
                  _buildTextField(
                    'Enter height',
                    _heightCtrl,
                    keyboard: TextInputType.number,
                    validator: (v) {
                      final h = int.tryParse(v!.trim());
                      if (h == null || h < 100 || h > 250) {
                        return 'Enter 100–250 cm';
                      }
                      return null;
                    },
                  ),
                  _buildLabel('Weight (kg)'),
                  _buildTextField(
                    'Enter weight',
                    _weightCtrl,
                    keyboard: TextInputType.number,
                    validator: (v) {
                      final w = int.tryParse(v!.trim());
                      if (w == null || w < 30 || w > 200) {
                        return 'Enter 30–200 kg';
                      }
                      return null;
                    },
                  ),
                  _buildLabel('Experience Level'),
                  _buildDropdown(['Beginner', 'Semi-Pro', 'Professional'], experience,
                      (val) => setState(() => experience = val)),
                  _buildLabel('Current Club (Optional)'),
                  _buildTextField('Enter club name', _clubCtrl, validator: (_) => null),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
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
