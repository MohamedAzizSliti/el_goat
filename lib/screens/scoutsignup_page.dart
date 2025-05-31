// Updated scout signup page for multiple profiles per user
// Allows inserting multiple scout profiles for the same user

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'success_page.dart';
import '../widgets/country_selector.dart';
import 'dart:async';

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

  // OTP verification state
  bool _showOTPVerification = false;
  bool _isVerifyingOTP = false;
  bool _isResendingOTP = false;
  int _resendCountdown = 60;
  Timer? _timer;
  String _errorMessage = '';
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

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
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _timer?.cancel();
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
      // Send OTP to user's email
      await _supabase.auth.signInWithOtp(email: _userEmail!);

      if (mounted) {
        setState(() {
          _showOTPVerification = true;
          _isSaving = false;
        });
        _startResendTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Code de vérification envoyé à $_userEmail'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        String errorMessage = 'Erreur lors de l\'envoi du code';

        // Handle specific error types
        if (error.toString().contains('email_rate_limit_exceeded')) {
          errorMessage =
              'Trop d\'emails envoyés. Veuillez attendre quelques minutes avant de réessayer.';
        } else if (error.toString().contains('over_email_send_rate_limit')) {
          errorMessage =
              'Limite d\'envoi d\'emails dépassée. Veuillez attendre 60 secondes avant de réessayer.';
        } else if (error.toString().contains('rate limit')) {
          errorMessage =
              'Limite de taux dépassée. Veuillez attendre un moment et réessayer.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyOTP() async {
    if (_otpCode.length != 6) {
      setState(
        () => _errorMessage = 'Veuillez entrer le code complet à 6 chiffres',
      );
      return;
    }

    setState(() {
      _isVerifyingOTP = true;
      _errorMessage = '';
    });

    try {
      final response = await _supabase.auth.verifyOTP(
        email: _userEmail!,
        token: _otpCode,
        type: OtpType.email,
      );

      if (response.user != null) {
        // OTP verified, now save the profile
        await _saveScoutProfile();
      } else {
        setState(
          () =>
              _errorMessage =
                  'Code de vérification invalide. Veuillez réessayer.',
        );
        _clearOTP();
      }
    } catch (e) {
      setState(
        () =>
            _errorMessage =
                'Vérification échouée. Veuillez vérifier votre code.',
      );
      _clearOTP();
    } finally {
      if (mounted) {
        setState(() => _isVerifyingOTP = false);
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
        Navigator.pushReplacementNamed(context, '/accueil');
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

  Future<void> _resendOTP() async {
    setState(() => _isResendingOTP = true);

    try {
      await _supabase.auth.signInWithOtp(email: _userEmail!);
      _startResendTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Code de vérification renvoyé à $_userEmail'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Échec du renvoi du code. Veuillez réessayer.';

      // Handle specific error types
      if (e.toString().contains('email_rate_limit_exceeded')) {
        errorMessage =
            'Trop d\'emails envoyés. Veuillez attendre quelques minutes avant de réessayer.';
      } else if (e.toString().contains('over_email_send_rate_limit')) {
        errorMessage =
            'Limite d\'envoi d\'emails dépassée. Veuillez attendre 60 secondes avant de réessayer.';
      } else if (e.toString().contains('rate limit')) {
        errorMessage =
            'Limite de taux dépassée. Veuillez attendre un moment et réessayer.';
      }

      setState(() => _errorMessage = errorMessage);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResendingOTP = false);
      }
    }
  }

  void _clearOTP() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _otpFocusNodes[0].requestFocus();
  }

  void _onOTPChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    if (_otpCode.length == 6) {
      _verifyOTP();
    }

    setState(() => _errorMessage = '');
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
            child:
                _showOTPVerification
                    ? _buildOTPVerification()
                    : _buildScoutForm(),
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

  Widget _buildOTPVerification() {
    return Column(
      children: [
        const SizedBox(height: 40),

        // Header
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
          child: const Icon(Icons.email, size: 40, color: Colors.white),
        ),

        const SizedBox(height: 24),
        const Text(
          'Vérification Email',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),
        Text(
          'Nous avons envoyé un code à 6 chiffres à\n${_userEmail ?? "votre email"}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 40),

        // OTP Input
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return Container(
              width: 50,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _otpControllers[index].text.isNotEmpty
                          ? Colors.blue[400]!
                          : Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                keyboardType: TextInputType.number,
                maxLength: 1,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => _onOTPChanged(value, index),
              ),
            );
          }),
        ),

        if (_errorMessage.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),

        // Verify Button
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
            onPressed: _isVerifyingOTP ? null : _verifyOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                _isVerifyingOTP
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text(
                      'Vérifier le Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
          ),
        ),

        const SizedBox(height: 24),

        // Resend Section
        Column(
          children: [
            Text(
              'Vous n\'avez pas reçu le code?',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (_resendCountdown > 0)
              Text(
                'Renvoyer dans ${_resendCountdown}s',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              )
            else
              TextButton(
                onPressed: _isResendingOTP ? null : _resendOTP,
                child:
                    _isResendingOTP
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                        )
                        : Text(
                          'Renvoyer le Code',
                          style: TextStyle(
                            color: Colors.blue[400],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
          ],
        ),
      ],
    );
  }
}
