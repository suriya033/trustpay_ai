import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/ai_review_model.dart';
import '../../models/milestone_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/sandbox_banner.dart';
import '../../widgets/status_badge.dart';
import 'paypal_checkout_modal.dart';
import 'submit_work_modal.dart';

class MilestoneDetailScreen extends StatefulWidget {
  final String projectId;
  final String milestoneId;

  const MilestoneDetailScreen({
    super.key,
    required this.projectId,
    required this.milestoneId,
  });

  @override
  State<MilestoneDetailScreen> createState() => _MilestoneDetailScreenState();
}

class _MilestoneDetailScreenState extends State<MilestoneDetailScreen> {
  bool _isRunningAiReview = false;

  MilestoneModel? _getMilestone() {
    final proj = context.watch<ProjectProvider>().currentProject;
    if (proj == null) return null;
    try {
      return proj.milestones.firstWhere((m) => m.id == widget.milestoneId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _refresh() async {
    await context.read<ProjectProvider>().fetchProjectById(widget.projectId);
  }

  Future<void> _triggerAiReview() async {
    setState(() => _isRunningAiReview = true);
    final projProvider = context.read<ProjectProvider>();
    final review = await projProvider.requestAiReview(
      projectId: widget.projectId,
      milestoneId: widget.milestoneId,
    );
    setState(() => _isRunningAiReview = false);

    if (!mounted) return;

    if (review != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gemini AI Review generated! Score: ${review.score}/100'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(projProvider.errorMessage ?? 'Failed to run AI review'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showClientDecisionDialog() {
    final feedbackCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Review Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verify work against the acceptance criteria and Gemini AI report.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Feedback / Instructions',
                hintText: 'Add notes for the freelancer...',
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<ProjectProvider>().clientDecision(
                    projectId: widget.projectId,
                    milestoneId: widget.milestoneId,
                    decision: 'revision_requested',
                    feedback: feedbackCtrl.text.trim(),
                  );
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Revision requested from freelancer'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            child: const Text('Request Revision',
                style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<ProjectProvider>().clientDecision(
                    projectId: widget.projectId,
                    milestoneId: widget.milestoneId,
                    decision: 'approved',
                    feedback: feedbackCtrl.text.trim(),
                  );
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Milestone approved! You can now pay via PayPal Sandbox.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Approve Milestone'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final milestone = _getMilestone();

    if (milestone == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Milestone Details')),
        body: Center(
          child: ElevatedButton(
            onPressed: _refresh,
            child: const Text('Reload Milestone'),
          ),
        ),
      );
    }

    final isClient = auth.isClient;
    final isFreelancer = auth.isFreelancer;
    final latestSub = milestone.latestSubmission;
    final aiReview = latestSub?.aiReview;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Milestone Details'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refresh),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SandboxBanner(),
              const SizedBox(height: 14),

              // Milestone Title & Amount Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusBadge(status: milestone.status),
                        Text(
                          CurrencyFormatter.format(milestone.amount,
                              currency: milestone.currency),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      milestone.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      milestone.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (milestone.suggestedDuration.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Estimated Duration: ${milestone.suggestedDuration}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Deliverables Card
              if (milestone.deliverables.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Agreed Deliverables',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...milestone.deliverables.map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              Expanded(
                                child: Text(d,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Acceptance Criteria Card
              if (milestone.acceptanceCriteria.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.checklist_rounded,
                              size: 18, color: AppColors.success),
                          SizedBox(width: 8),
                          Text(
                            'Acceptance Criteria',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...milestone.acceptanceCriteria.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  size: 16, color: AppColors.success),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(c,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Payment Status / Receipt Section
              if (milestone.isPaid && milestone.payment != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.success.withAlpha(80)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_rounded,
                              color: AppColors.success, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Paid via PayPal Sandbox',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Receipt ID: ${milestone.payment!.receiptId}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'PayPal Order: ${milestone.payment!.paypalOrderId}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        'Capture ID: ${milestone.payment!.paypalCaptureId}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        'Date: ${DateFormatter.formatWithTime(milestone.payment!.paidAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Latest Submission & AI Review Section
              if (latestSub != null) ...[
                const Text(
                  'Work Submission & Verification',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBackground,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Version ${latestSub.version}',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            DateFormatter.formatRelative(latestSub.submittedAt),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        latestSub.description,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                      if (latestSub.githubUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.code_rounded,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                latestSub.githubUrl,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (latestSub.liveDemoUrl.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.launch_rounded,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                latestSub.liveDemoUrl,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (latestSub.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Notes: ${latestSub.notes}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Gemini AI Review Report Card
                if (aiReview != null) ...[
                  _buildAiReportCard(aiReview),
                  const SizedBox(height: 14),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD8B4FE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Color(0xFF7E22CE), size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'AI review has not been triggered for this submission yet.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF581C87),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isFreelancer || isClient)
                          ElevatedButton(
                            onPressed:
                                _isRunningAiReview ? null : _triggerAiReview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7E22CE),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                            ),
                            child: _isRunningAiReview
                                ? const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('Run AI Audit',
                                    style: TextStyle(fontSize: 11)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Client Decision / Review Card
                if (latestSub.clientReview != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: latestSub.clientReview!.isApproved
                          ? AppColors.successLight
                          : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: latestSub.clientReview!.isApproved
                            ? AppColors.success.withAlpha(80)
                            : AppColors.error.withAlpha(80),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              latestSub.clientReview!.isApproved
                                  ? Icons.check_circle_rounded
                                  : Icons.replay_rounded,
                              color: latestSub.clientReview!.isApproved
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              latestSub.clientReview!.isApproved
                                  ? 'Client Approved Work'
                                  : 'Client Requested Revisions',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: latestSub.clientReview!.isApproved
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        if (latestSub.clientReview!.feedback.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Client Feedback: "${latestSub.clientReview!.feedback}"',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ],

              // Action Toolbar
              const SizedBox(height: 10),
              if (isFreelancer &&
                  (milestone.isInProgress || milestone.isNeedsRevision)) ...[
                CustomButton(
                  text: 'Submit Work Evidence',
                  icon: Icons.upload_file_rounded,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => SubmitWorkModal(
                        projectId: widget.projectId,
                        milestone: milestone,
                        onSubmitSuccess: _refresh,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              if (isClient &&
                  (milestone.isSubmitted || milestone.isUnderAiReview)) ...[
                CustomButton(
                  text: 'Review & Decide (Approve / Revise)',
                  icon: Icons.rate_review_rounded,
                  color: AppColors.primary,
                  onPressed: _showClientDecisionDialog,
                ),
                const SizedBox(height: 12),
              ],

              if (isClient && milestone.isApproved) ...[
                CustomButton(
                  text: 'Release Payment via PayPal Sandbox',
                  icon: Icons.payments_rounded,
                  color: AppColors.paypalBlue,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => PayPalCheckoutModal(
                        projectId: widget.projectId,
                        milestone: milestone,
                        onPaymentSuccess: _refresh,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiReportCard(AiReviewModel ai) {
    Color scoreColor = ai.score >= 80 ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8B4FE), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF7E22CE), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Gemini AI Verification Report',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF581C87),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${ai.score}/100',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ai.summary,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textPrimary, height: 1.3),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const Text(
            'Criteria Compliance Checks:',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          ...ai.criteriaChecks.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    c.satisfied ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: c.satisfied ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.criterion,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          c.explanation,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (ai.identifiedRisks.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Identified Risks & Recommendations:',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning),
            ),
            const SizedBox(height: 4),
            ...ai.identifiedRisks.map(
              (r) => Text('• $r',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ),
          ],
        ],
      ),
    );
  }
}
