import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _resetCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  String? _generatedCode;

  @override
  void dispose() {
    _emailController.dispose();
    _resetCodeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final code = await AuthService.forgotPassword(email);
      setState(() {
        _codeSent = true;
        _generatedCode = code;
        if (code != null) {
          _resetCodeController.text = code;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              code != null
                  ? 'Reset code generated: $code'
                  : 'Check your email for the reset code',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    final code = _resetCodeController.text.trim();
    final newPassword = _newPasswordController.text;

    if (code.isEmpty || newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter valid code and password (min 6 chars)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.resetPassword(
        email: email,
        resetCode: code,
        newPassword: newPassword,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully! Please sign in.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Password Recovery',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your account email to receive a password reset code.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _emailController,
                label: 'Account Email',
                hint: 'name@example.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              if (!_codeSent) ...[
                CustomButton(
                  text: 'Send Reset Code',
                  isLoading: _isLoading,
                  onPressed: _handleSendCode,
                ),
              ] else ...[
                if (_generatedCode != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.key_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Demo Reset Code: $_generatedCode',
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                CustomTextField(
                  controller: _resetCodeController,
                  label: 'Reset Code',
                  hint: '6-digit hex code',
                  prefixIcon: Icons.pin_outlined,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  hint: 'At least 6 characters',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Confirm New Password',
                  isLoading: _isLoading,
                  onPressed: _handleResetPassword,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
