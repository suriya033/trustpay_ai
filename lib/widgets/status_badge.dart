import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'paid':
        bg = AppColors.successLight;
        text = AppColors.success;
        label = 'Paid via PayPal';
        icon = Icons.check_circle_rounded;
        break;
      case 'approved':
        bg = const Color(0xFFE0F2FE);
        text = const Color(0xFF0369A1);
        label = 'Approved • Ready to Pay';
        icon = Icons.verified_rounded;
        break;
      case 'in_progress':
        bg = AppColors.primaryLight;
        text = AppColors.primary;
        label = 'In Progress';
        icon = Icons.play_arrow_rounded;
        break;
      case 'under_ai_review':
        bg = const Color(0xFFF3E8FF);
        text = const Color(0xFF7E22CE);
        label = 'Under Gemini AI Review';
        icon = Icons.auto_awesome_rounded;
        break;
      case 'submitted':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFB45309);
        label = 'Work Submitted';
        icon = Icons.upload_file_rounded;
        break;
      case 'needs_revision':
        bg = AppColors.errorLight;
        text = AppColors.error;
        label = 'Needs Revision';
        icon = Icons.replay_rounded;
        break;
      case 'payment_pending':
        bg = const Color(0xFFFEF9C3);
        text = const Color(0xFFA16207);
        label = 'Payment Pending';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'active':
        bg = AppColors.successLight;
        text = AppColors.success;
        label = 'Active Agreement';
        icon = Icons.handshake_rounded;
        break;
      case 'completed':
        bg = AppColors.successLight;
        text = AppColors.success;
        label = 'Project Completed';
        icon = Icons.task_alt_rounded;
        break;
      case 'pending_agreement':
        bg = AppColors.warningLight;
        text = AppColors.warning;
        label = 'Pending Agreement';
        icon = Icons.pending_actions_rounded;
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        text = AppColors.textSecondary;
        label = 'Pending';
        icon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withAlpha(50), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
