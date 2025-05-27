// lib/screens/footballersignup_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/success_page.dart';
import '../theme/app_theme.dart';
import '../widgets/country_selector.dart';

class FootballerSignUpPage extends StatefulWidget {
  final String userId;
  const FootballerSignUpPage({super.key, required this.userId});

  @override
  State<FootballerSignUpPage> createState() => _FootballerSignUpPageState();
}

class _FootballerSignUpPageState extends State<FootballerSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Controllers
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _clubCtrl = TextEditingController();

  // Dropdown values
  String? position;
  String? foot;
  String? experience;
  String? nationality;

  final supabase = Supabase.instance.client;

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
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      _dobCtrl.text =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate nationality
    if (nationality == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your nationality'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Parse date
      final dobParts = _dobCtrl.text.split('/');
      final dobIso =
          '${dobParts[2]}-${dobParts[1].padLeft(2, '0')}-${dobParts[0].padLeft(2, '0')}';

      await supabase.from('footballer_profiles').insert({
        'user_id': widget.userId,
        'full_name': _fullNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'dob': dobIso,
        'nationality': nationality,
        'position': position,
        'preferred_foot': foot,
        'height_cm': int.tryParse(_heightCtrl.text.trim()),
        'weight_kg': int.tryParse(_weightCtrl.text.trim()),
        'experience_level': experience,
        'current_club':
            _clubCtrl.text.trim().isEmpty ? null : _clubCtrl.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update main profile
      await supabase
          .from('profiles')
          .update({
            'full_name': _fullNameCtrl.text.trim(),
            'role': 'footballer',
          })
          .eq('id', widget.userId);

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
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
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
                          color: AppTheme.textSecondaryDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Personal Information
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator:
                      (v) =>
                          (v == null || v.isEmpty)
                              ? 'This field is required'
                              : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    final val = v!.trim();
                    if (!RegExp(r'^\d{8,15}$').hasMatch(val)) {
                      return 'Enter 8–15 digits';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Nationality Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nationality',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CountrySelector(
                      selectedCountry: nationality,
                      onCountrySelected: (country) {
                        setState(() => nationality = country);
                      },
                      showFlags: true,
                      showPopularFirst: true,
                      hintText: 'Select your nationality',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _dobCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    hintText: 'DD/MM/YYYY',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  readOnly: true,
                  onTap: _selectDate,
                  validator: (v) {
                    final val = v!.trim();
                    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(val)) {
                      return 'Use DD/MM/YYYY format';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Football Information
                Text(
                  'Football Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: position,
                  decoration: const InputDecoration(
                    labelText: 'Position',
                    hintText: 'Select your position',
                  ),
                  items:
                      ['Goalkeeper', 'Defender', 'Midfielder', 'Striker']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => position = val),
                  validator:
                      (v) => v == null ? 'Please select a position' : null,
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: foot,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Foot',
                    hintText: 'Select your preferred foot',
                  ),
                  items:
                      ['Left', 'Right', 'Both']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => foot = val),
                  validator:
                      (v) => v == null ? 'Please select preferred foot' : null,
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: experience,
                  decoration: const InputDecoration(
                    labelText: 'Experience Level',
                    hintText: 'Select your experience level',
                  ),
                  items:
                      ['Beginner', 'Semi-Pro', 'Professional']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => experience = val),
                  validator:
                      (v) =>
                          v == null ? 'Please select experience level' : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _clubCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Current Club (Optional)',
                    hintText: 'Enter your current club',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),

                const SizedBox(height: 24),

                // Physical Information
                Text(
                  'Physical Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _heightCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    hintText: 'Enter your height',
                    prefixIcon: Icon(Icons.height_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final h = int.tryParse(v!.trim());
                    if (h == null || h < 100 || h > 250) {
                      return 'Height must be between 100-250 cm';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _weightCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'Enter your weight',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final w = int.tryParse(v!.trim());
                    if (w == null || w < 30 || w > 200) {
                      return 'Weight must be between 30-200 kg';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
}
