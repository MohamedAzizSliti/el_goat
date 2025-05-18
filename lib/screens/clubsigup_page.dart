// Updated ClubSignUpPage to support multiple profiles per user

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'success_page.dart';

class ClubSignUpPage extends StatefulWidget {
  final String userId;
  const ClubSignUpPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<ClubSignUpPage> createState() => _ClubSignUpPageState();
}

class _ClubSignUpPageState extends State<ClubSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _clubNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _isSaving = false;
  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _clubNameCtrl.dispose();
    _locationCtrl.dispose();
    _websiteCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = _supabase.auth.currentUser;
      final response = await _supabase
          .from('club_profiles')
          .insert({
            'user_id': widget.userId,
            'email': user?.email,
            'club_name': _clubNameCtrl.text.trim(),
            'location': _locationCtrl.text.trim(),
            'website': _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
            'description': _descriptionCtrl.text.trim(),
            'created_at': DateTime.now().toIso8601String(),
          });

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
            content: Text('Erreur: ${error.toString()}'),
            backgroundColor: Colors.red,
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Club Sign Up'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Nom du club'),
                _buildField(_clubNameCtrl, 'Entrez le nom du club'),

                _buildLabel('Localisation'),
                _buildField(_locationCtrl, 'Ville, région'),

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
                _buildField(
                  _descriptionCtrl,
                  'Décrivez votre club',
                  maxLines: 3,
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Enregistrer', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
      );

  Widget _buildField(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
      validator: validator ?? (v) => v == null || v.isEmpty ? 'Requis' : null,
    );
  }
}