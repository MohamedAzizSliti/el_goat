// lib/screens/footballersignup_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/success_page.dart';
import '../theme/app_theme.dart';

class FootballerSignUpPage extends StatefulWidget {
  final String userId;
  const FootballerSignUpPage({super.key, required this.userId});


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
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceLight,
              onSurface: AppTheme.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobCtrl.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
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
        'date_of_birth': dobFormatted,
        'position': position ?? 'Not specified',
        'preferred_foot': foot ?? 'Not specified',
        'height_cm': double.parse(_heightCtrl.text.trim()),
        'weight_kg': double.parse(_weightCtrl.text.trim()),
        'phone': _phoneCtrl.text.trim(),

        'current_club':
            _clubCtrl.text.trim().isEmpty ? 'None' : _clubCtrl.text.trim(),
        'experience_level': experience ?? 'Not specified',
        'created_at': DateTime.now().toIso8601String(),
        'last_seen': DateTime.now().toIso8601String(),
      };

      // First try to get existing profile
      final existingProfile =
          await _supabase
              .from('footballer_profiles')
              .select()
              .eq('user_id', widget.userId)
              .maybeSingle();

      if (existingProfile != null) {
        // Update existing profile
        await _supabase
            .from('footballer_profiles')
            .update(profile)
            .eq('user_id', widget.userId);
      } else {
        // Create new profile
        await _supabase.from('footballer_profiles').insert(profile);
      }

      // Try to create player_skills entry
      try {
        // First try to create the table if it doesn't exist
        await _supabase.rpc('create_player_skills_table');

        // Then create the player skills entry
        await _supabase.from('player_skills').upsert({
          'user_id': widget.userId,
          'technical_skills': {},
          'physical_attributes': {},
          'mental_attributes': {},
        }, onConflict: 'user_id');
      } catch (e) {
        print('Error creating player skills: $e');
        // Don't throw error - we'll handle this in the profile page
      }

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
            backgroundColor: AppTheme.errorColor,
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
  }) => TextFormField(
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
      prefixIcon:
          prefixIcon != null ? Icon(prefixIcon, color: Colors.grey) : null,
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
    validator: (v) => (v == null || v.isEmpty) ? 'Please select' : null,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        centerTitle: true,
      ),
      body: SafeArea(
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
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sports_soccer,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Footballer Profile',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete your profile to start your football journey',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Personal Information Section
                _buildSection('Personal Information', [
                  _buildTextField(
                    'Full Name',
                    'Enter your full name',
                    _fullNameCtrl,
                    prefixIcon: Icons.person_outline,
                  ),
                  _buildTextField(
                    'Phone Number',
                    'Enter your phone number',
                    _phoneCtrl,
                    keyboard: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    validator: (v) {
                      final val = v!.trim();
                      if (!RegExp(r'^\d{8,15}$').hasMatch(val)) {
                        return 'Enter 8–15 digits';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    'Date of Birth',
                    'DD/MM/YYYY',
                    _dobCtrl,
                    prefixIcon: Icons.calendar_today_outlined,
                    readOnly: true,
                    onTap: _selectDate,
                    validator: (v) {
                      final val = v!.trim();
                      if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(val)) {
                        return 'Use DD/MM/YYYY format';
                      }
                      final parts = val.split('/');
                      final iso =
                          '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
                      final date = DateTime.tryParse(iso);
                      if (date == null) return 'Invalid date';
                      final age = DateTime.now().difference(date).inDays ~/ 365;
                      if (age < 10 || age > 80) {
                        return 'Age must be between 10-80';
                      }
                      return null;
                    },
                  ),
                ]),

                // Football Information Section
                _buildSection('Football Information', [
                  _buildDropdown(
                    'Position',

                    ['Goalkeeper', 'Defender', 'Midfielder', 'Striker'],
                    position,
                    (val) => setState(() => position = val),
                  ),
                  _buildDropdown(
                    'Preferred Foot',

                    ['Left', 'Right', 'Both'],
                    foot,
                    (val) => setState(() => foot = val),
                  ),
                  _buildDropdown(
                    'Experience Level',
                    ['Beginner', 'Semi-Pro', 'Professional'],
                    experience,
                    (val) => setState(() => experience = val),
                  ),
                  _buildTextField(
                    'Current Club',
                    'Enter your current club (optional)',
                    _clubCtrl,
                    prefixIcon: Icons.business_outlined,
                    validator: (_) => null,
                  ),
                ]),

                // Physical Information Section
                _buildSection('Physical Information', [

                  _buildTextField(
                    'Height (cm)',
                    'Enter your height',
                    _heightCtrl,
                    keyboard: TextInputType.number,
                    prefixIcon: Icons.height_outlined,
                    validator: (v) {
                      final h = int.tryParse(v!.trim());
                      if (h == null || h < 100 || h > 250) {
                        return 'Height must be between 100-250 cm';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    'Weight (kg)',
                    'Enter your weight',
                    _weightCtrl,
                    keyboard: TextInputType.number,
                    prefixIcon: Icons.monitor_weight_outlined,
                    validator: (v) {
                      final w = int.tryParse(v!.trim());
                      if (w == null || w < 30 || w > 200) {
                        return 'Weight must be between 30-200 kg';
                      }
                      return null;
                    },
                  ),
                ]),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                  _buildLabel('Experience Level'),
                  _buildDropdown(
                    ['Beginner', 'Semi-Pro', 'Professional'],
                    experience,
                    (val) => setState(() => experience = val),
                  ),
                  _buildLabel('Current Club (Optional)'),
                  _buildTextField(
                    'Enter club name',
                    _clubCtrl,
                    validator: (_) => null,
                  ),
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
                      child:
                          _isSaving
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Save & Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
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
                            : const Text('Complete Profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController ctrl, {
    TextInputType keyboard = TextInputType.text,
    IconData? prefixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          ),
          validator:
              validator ??
              (v) => (v == null || v.isEmpty) ? 'This field is required' : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? value,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(hintText: 'Please select'),
          items:
              items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
          onChanged: onChanged,
          validator:
              (v) =>
                  (v == null || v.isEmpty) ? 'Please make a selection' : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
