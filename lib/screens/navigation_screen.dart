import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'client/client_home_screen.dart';
import 'client/create_project_screen.dart';
import 'freelancer/freelancer_home_screen.dart';
import 'payments/transactions_screen.dart';
import 'profile/profile_screen.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isClient = auth.isClient;

    final List<Widget> screens = isClient
        ? [
            const ClientHomeScreen(),
            const CreateProjectScreen(),
            const TransactionsScreen(),
            const ProfileScreen(),
          ]
        : [
            const FreelancerHomeScreen(),
            const TransactionsScreen(),
            const ProfileScreen(),
          ];

    final List<BottomNavigationBarItem> navItems = isClient
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Projects',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline_rounded),
              activeIcon: Icon(Icons.add_circle_rounded),
              label: 'Create',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Receipts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.work_rounded),
              label: 'Workspace',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Receipts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ];

    // Bound current index safely if role toggles
    final safeIndex = _currentIndex < screens.length ? _currentIndex : 0;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: navItems,
      ),
    );
  }
}
