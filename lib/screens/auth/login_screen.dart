import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/sandbox_banner.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  String _activeDemoRole = ''; // 'client' | 'freelancer'

  @override
  void initState() {
    super.initState();
    if (ApiConstants.customHost.contains('10.236.71.84')) {
      ApiConstants.customHost = '';
      StorageService.saveCustomHost('');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _quickFill(String email, String password, String role) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
      _activeDemoRole = role;
    });
  }

  void _showServerSettings() {
    final hostController = TextEditingController(
      text: ApiConstants.customHost.isEmpty
          ? ApiConstants.baseUrl
          : ApiConstants.customHost,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text('API Server Host', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend API server URL used for database, AI milestone generation, and PayPal Sandbox calls:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: hostController,
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.160:5000',
                prefixIcon: Icon(Icons.link_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('192.168.1.160:5000', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    hostController.text = 'http://192.168.1.160:5000';
                  },
                ),
                ActionChip(
                  label: const Text('10.0.2.2:5000', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    hostController.text = 'http://10.0.2.2:5000';
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              ApiConstants.customHost = '';
              await StorageService.saveCustomHost('');
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) setState(() {});
            },
            child: const Text('Reset Default'),
          ),
          ElevatedButton(
            onPressed: () async {
              ApiConstants.customHost = hostController.text.trim();
              await StorageService.saveCustomHost(ApiConstants.customHost);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) setState(() {});
            },
            child: const Text('Save Host'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (ApiConstants.customHost.contains('10.236.71.84')) {
      ApiConstants.customHost = '';
      await StorageService.saveCustomHost('');
      if (mounted) setState(() {});
    }

    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  authProvider.errorMessage ?? 'Login failed. Please check credentials or host IP.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SandboxBanner(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Utility Bar: Server IP Pill + Settings
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _showServerSettings,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryBackground,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    ApiConstants.baseUrl.replaceAll('http://', ''),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit, size: 11, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 22),
                            onPressed: _showServerSettings,
                            tooltip: 'API Server Settings',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Brand Header Card
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(40),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.shield_rounded,
                                color: AppColors.textInverse,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TrustPay AI',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'SMART MILESTONES • PAYPAL ESCROW',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sign in to manage verified project deliverables and release milestone payments.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email Field
                      CustomTextField(
                        controller: _emailController,
                        label: 'Work Email Address',
                        hint: 'name@example.com',
                        prefixIcon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Please enter your email';
                          if (!val.contains('@')) return 'Enter a valid email address';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: '••••••••••••',
                        prefixIcon: Icons.lock_outline_rounded,
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
                          if (val == null || val.isEmpty) return 'Please enter your password';
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Sign In Button
                      CustomButton(
                        text: 'Sign In to Workspace',
                        icon: Icons.login_rounded,
                        isLoading: authProvider.isLoading,
                        onPressed: _handleLogin,
                      ),
                      const SizedBox(height: 24),

                      // Hackathon 1-Tap Quick Fill Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(6),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.bolt_rounded, size: 18, color: AppColors.warning),
                                    SizedBox(width: 6),
                                    Text(
                                      'Quick Demo Accounts',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '1-TAP AUTOFILL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Client Tile
                            _buildDemoRoleTile(
                              role: 'client',
                              name: 'Sarah Jenkins',
                              roleLabel: 'Client / Fund Milestones',
                              email: 'client@trustpay.ai',
                              password: 'Password123!',
                              icon: Icons.business_center_rounded,
                              iconBg: AppColors.primaryLight,
                              iconColor: AppColors.primary,
                            ),
                            const SizedBox(height: 8),

                            // Freelancer Tile
                            _buildDemoRoleTile(
                              role: 'freelancer',
                              name: 'Alex Rivera',
                              roleLabel: 'Freelancer / Submit Deliverables',
                              email: 'freelancer@trustpay.ai',
                              password: 'Password123!',
                              icon: Icons.code_rounded,
                              iconBg: const Color(0xFFE0F2FE),
                              iconColor: const Color(0xFF0369A1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "New to TrustPay AI? ",
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Create Account',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Trust Badges Footer
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildTrustBadge(Icons.lock_rounded, '256-Bit SSL'),
                            const SizedBox(width: 14),
                            _buildTrustBadge(Icons.auto_awesome, 'Gemini AI Verified'),
                            const SizedBox(width: 14),
                            _buildTrustBadge(Icons.shield_outlined, 'PayPal Sandbox'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoRoleTile({
    required String role,
    required String name,
    required String roleLabel,
    required String email,
    required String password,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    final isSelected = _activeDemoRole == role;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _quickFill(email, password, role),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 14),
                      ],
                    ],
                  ),
                  Text(
                    roleLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                ),
              ),
              child: Text(
                isSelected ? 'Filled' : 'Select',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
