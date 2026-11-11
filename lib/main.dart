import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/api_constants.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/project_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/navigation_screen.dart';
import 'widgets/loading_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConstants.init();
  runApp(const TrustPayApp());
}

class TrustPayApp extends StatelessWidget {
  const TrustPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initAuth()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        title: 'TrustPay AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_rounded,
                size: 56,
                color: AppColors.primary,
              ),
              SizedBox(height: 16),
              Text(
                'TrustPay AI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Smart Milestones. Transparent Payments.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 28),
              LoadingIndicator(),
            ],
          ),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return const NavigationScreen();
    }

    return const LoginScreen();
  }
}
