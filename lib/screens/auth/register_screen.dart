import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedRole = 'client'; // 'client' | 'freelancer'
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join TrustPay AI',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose your account role to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                // Role Selector Segment
                const Text(
                  'I want to:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'client'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'client'
                                ? AppColors.primaryLight
                                : AppColors.secondaryBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedRole == 'client'
                                  ? AppColors.primary
                                  : AppColors.cardBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.business_center_rounded,
                                color: _selectedRole == 'client'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Hire (Client)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: _selectedRole == 'client'
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Fund & Pay Milestones',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _selectedRole == 'client'
                                      ? AppColors.primaryDark
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'freelancer'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'freelancer'
                                ? AppColors.primaryLight
                                : AppColors.secondaryBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedRole == 'freelancer'
                                  ? AppColors.primary
                                  : AppColors.cardBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.code_rounded,
                                color: _selectedRole == 'freelancer'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Work (Freelancer)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: _selectedRole == 'freelancer'
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Deliver & Get Paid',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _selectedRole == 'freelancer'
                                      ? AppColors.primaryDark
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Alex Morgan',
                  prefixIcon: Icons.person_outline,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter full name';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'name@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter email';
                    if (!val.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'At least 6 characters',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Confirm your password';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                CustomButton(
                  text: 'Create Account',
                  isLoading: authProvider.isLoading,
                  onPressed: _handleRegister,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
