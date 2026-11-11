import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class SandboxBanner extends StatelessWidget {
  const SandboxBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 15, color: AppColors.warning),
          SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'PAYPAL SANDBOX MODE • TEST TRANSACTIONS ONLY',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
