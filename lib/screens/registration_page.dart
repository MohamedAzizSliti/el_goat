// lib/screens/registration_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'clubsigup_page.dart';
import 'scoutsignup_page.dart';
import 'footballersignup_page.dart';
import '../theme/app_theme.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  bool _obscurePassword = true;

  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(Supabase.instance.client);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _otp;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Set your Supabase project URL and service_role key here

      final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final String serviceRoleKey =
          dotenv.env['SUPABASE_SERVICE_ROLE_SECRET'] ?? '';
      final user = await _authService.signUpWithOtp(
        email: _emailController.text.trim(),
        otp: _otp,
        fullName: _nameController.text.trim(),
        role: _selectedCategory!,
        supabaseUrl: supabaseUrl,
        serviceRoleKey: serviceRoleKey,
      );
      print("user " + user.toString());

      if (user == null) {
        // OTP generated and sent, prompt user to enter OTP
        setState(() => _isLoading = false);
        await showDialog(
          context: context,
          builder: (context) {
            final otpController = TextEditingController();
            return AlertDialog(
              title: const Text('Enter OTP'),
              content: TextField(
                controller: otpController,
                decoration: const InputDecoration(labelText: 'OTP Code'),
                keyboardType: TextInputType.number,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    setState(() {
                      _otp = otpController.text.trim();
                    });
                    await _submitForm();
                  },
                  child: const Text('Verify'),
                ),
              ],
            );
          },
        );
        return;
      }

      if (!mounted) return;

      // Navigate to role-specific form
      late Widget nextPage;
      switch (_selectedCategory!.toLowerCase()) {
        case 'footballer':
          nextPage = FootballerSignUpPage(userId: user.id, name: _nameController.text.trim(), email: _emailController.text.trim());
          break;
        case 'scout':
          nextPage = ScoutSignUpPage(userId: user.id, name: _nameController.text.trim(), email: _emailController.text.trim());
          break;
        case 'club':
          nextPage = ClubSignUpPage(userId: user.id, name: _nameController.text.trim(), email: _emailController.text.trim());
          break;
        default:
          throw Exception('Invalid category');
      }

      await Supabase.instance.client.from('user_roles').upsert({
        'user_id': user.id,
        'role': _selectedCategory!.toLowerCase(),
      }, onConflict: 'user_id');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
      );
    } catch (e) {
      if (!mounted) return;
      print("error " + e.toString());
      String message = 'Registration failed: ';
      if (e.toString().contains('already registered')) {
        message += 'This email is already registered. Please login instead.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: 'Login',
              onPressed:
                  () => Navigator.pushReplacementNamed(context, '/login'),
            ),
          ),
        );
      } else {
        print(e.toString());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message + e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildRoleCard(
    String role,
    IconData icon,
    String description,
    Color color,
  ) {
    final isSelected = _selectedCategory == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = role),
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.1) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? color : AppTheme.textSecondaryLight,
            ),
            const SizedBox(height: 8),
            Text(
              role,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo and Title Section
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
                      const SizedBox(height: 24),
                      Text(
                        'Join El Goat',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your football community account',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Login/Register Toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/login'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Login',
                              textAlign: TextAlign.center,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textSecondaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Sign Up',
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Full Name Field
                TextFormField(
                  controller: _nameController,
                  validator:
                      (v) => (v ?? '').isEmpty ? 'Enter your full name' : null,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),

                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if ((v ?? '').isEmpty) return 'Enter your email';
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(v!)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator:
                      (v) =>
                          (v ?? '').length < 8
                              ? 'Password must be at least 8 characters'
                              : null,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed:
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Role Selection
                Text(
                  'Choose Your Role',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select the role that best describes you in the football community',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 24),

                // Role Selection Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    _buildRoleCard(
                      'Footballer',
                      Icons.sports_soccer,
                      'Player seeking opportunities',
                      AppTheme.primaryColor,
                    ),
                    _buildRoleCard(
                      'Scout',
                      Icons.search,
                      'Talent evaluator',
                      AppTheme.secondaryColor,
                    ),
                    _buildRoleCard(
                      'Club',
                      Icons.business,
                      'Team organization',
                      AppTheme.accentColor,
                    ),
                  ],
                ),

                if (_selectedCategory == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Please select your role',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isLoading
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
                          : const Text('Create Account'),
                ),

                const SizedBox(height: 24),

                // Terms and Privacy
                Text(
                  'By creating an account, you agree to our Terms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                ),

                const SizedBox(height: 32),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
