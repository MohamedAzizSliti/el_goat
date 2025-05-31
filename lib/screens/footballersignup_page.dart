// lib/screens/footballersignup_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/success_page.dart';
import '../theme/app_theme.dart';
import '../widgets/country_selector.dart';
import 'dart:async';

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

  // OTP verification state
  bool _showOTPVerification = false;
  bool _isVerifyingOTP = false;
  bool _isResendingOTP = false;
  int _resendCountdown = 60;
  Timer? _timer;
  String _errorMessage = '';
  String _userEmail = '';
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _getUserEmail();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _clubCtrl.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _getUserEmail() {
    final user = supabase.auth.currentUser;
    if (user != null && user.email != null) {
      _userEmail = user.email!;
    }
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

    if (_userEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not found. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Send OTP to user's email
      await supabase.auth.signInWithOtp(email: _userEmail);

      if (mounted) {
        setState(() {
          _showOTPVerification = true;
          _isSaving = false;
        });
        _startResendTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code sent to $_userEmail'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        String errorMessage = 'Error sending verification code';

        // Handle specific error types
        if (error.toString().contains('email_rate_limit_exceeded')) {
          errorMessage =
              'Too many emails sent. Please wait a few minutes before trying again.';
        } else if (error.toString().contains('over_email_send_rate_limit')) {
          errorMessage =
              'Email rate limit exceeded. Please wait 60 seconds before trying again.';
        } else if (error.toString().contains('rate limit')) {
          errorMessage =
              'Rate limit exceeded. Please wait a moment and try again.';
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
      setState(() => _errorMessage = 'Please enter the complete 6-digit code');
      return;
    }

    setState(() {
      _isVerifyingOTP = true;
      _errorMessage = '';
    });

    try {
      final response = await supabase.auth.verifyOTP(
        email: _userEmail,
        token: _otpCode,
        type: OtpType.email,
      );

      if (response.user != null) {
        // OTP verified, now save the profile
        await _saveFootballerProfile();
      } else {
        setState(
          () => _errorMessage = 'Invalid verification code. Please try again.',
        );
        _clearOTP();
      }
    } catch (e) {
      setState(
        () => _errorMessage = 'Verification failed. Please check your code.',
      );
      _clearOTP();
    } finally {
      if (mounted) {
        setState(() => _isVerifyingOTP = false);
      }
    }
  }

  Future<void> _saveFootballerProfile() async {
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
        Navigator.pushReplacementNamed(context, '/accueil');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resendOTP() async {
    setState(() => _isResendingOTP = true);

    try {
      await supabase.auth.signInWithOtp(email: _userEmail);
      _startResendTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code resent to $_userEmail'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Failed to resend code. Please try again.';

      // Handle specific error types
      if (e.toString().contains('email_rate_limit_exceeded')) {
        errorMessage =
            'Too many emails sent. Please wait a few minutes before trying again.';
      } else if (e.toString().contains('over_email_send_rate_limit')) {
        errorMessage =
            'Email rate limit exceeded. Please wait 60 seconds before trying again.';
      } else if (e.toString().contains('rate limit')) {
        errorMessage =
            'Rate limit exceeded. Please wait a moment and try again.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
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
                    : _buildFootballerForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildFootballerForm() {
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
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                    (v == null || v.isEmpty) ? 'This field is required' : null,
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
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
            onChanged: (val) => setState(() => position = val),
            validator: (v) => v == null ? 'Please select a position' : null,
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
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
            onChanged: (val) => setState(() => foot = val),
            validator: (v) => v == null ? 'Please select preferred foot' : null,
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
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
            onChanged: (val) => setState(() => experience = val),
            validator:
                (v) => v == null ? 'Please select experience level' : null,
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
              colors: [Colors.orange[400]!, Colors.red[400]!],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange[400]!.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.email, size: 40, color: Colors.white),
        ),

        const SizedBox(height: 24),
        const Text(
          'Email Verification',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),
        Text(
          'We sent a 6-digit code to\n$_userEmail',
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
                          ? Colors.orange[400]!
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
              colors: [Colors.orange[400]!, Colors.orange[600]!],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.orange[400]!.withValues(alpha: 0.3),
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
                      'Verify Code',
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
              'Didn\'t receive the code?',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (_resendCountdown > 0)
              Text(
                'Resend in ${_resendCountdown}s',
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
                              Colors.orange,
                            ),
                          ),
                        )
                        : Text(
                          'Resend Code',
                          style: TextStyle(
                            color: Colors.orange[400],
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
