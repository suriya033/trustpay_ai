import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/milestone_model.dart';
import '../../models/project_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/sandbox_banner.dart';
import '../../widgets/status_badge.dart';
import 'milestone_detail_screen.dart';
import 'paypal_checkout_modal.dart';
import 'submit_work_modal.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProject();
    });
  }

  Future<void> _loadProject() async {
    await context.read<ProjectProvider>().fetchProjectById(widget.projectId);
  }

  void _showAgreementSnapshot(ProjectAgreement agreement) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Immutable Agreement Snapshot'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                agreement.terms,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Client Accepted: ${DateFormatter.formatWithTime(agreement.clientAcceptedAt)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Freelancer Accepted: ${DateFormatter.formatWithTime(agreement.freelancerAcceptedAt)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _respondToAgreementDialog(String action) {
    final changeCtrl = TextEditingController();

    if (action == 'accept') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Accept Project Agreement'),
          content: const Text(
            'By accepting, you agree to fulfill the deliverables and acceptance criteria for the funded milestones. An immutable copy of this contract will be stored.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await context
                    .read<ProjectProvider>()
                    .respondToAgreement(widget.projectId, action: 'accept');
                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Agreement accepted! Project is now active.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Confirm & Accept'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Request Agreement Changes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Explain what terms, budgets, or milestones require adjustment:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: changeCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. Please extend duration for Milestone 2 by 1 week...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await context.read<ProjectProvider>().respondToAgreement(
                      widget.projectId,
                      action: 'request_changes',
                      changeRequest: changeCtrl.text.trim(),
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Change request submitted to client.'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              },
              child: const Text('Submit Request'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final projProvider = context.watch<ProjectProvider>();
    final project = projProvider.currentProject;

    if (projProvider.isLoading && project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project Details')),
        body: const LoadingIndicator(message: 'Loading project and milestones...'),
      );
    }

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project Details')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Project not found or access restricted.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadProject,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final isClient = auth.isClient;
    final isFreelancer = auth.isFreelancer;
    final agreement = project.agreement;
    final needsFreelancerAcceptance =
        isFreelancer && agreement != null && !agreement.freelancerAccepted;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(project.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProject,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProject,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SandboxBanner(),
                const SizedBox(height: 16),

                // Project Overview Card
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
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              project.category,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          StatusBadge(status: project.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        project.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Budget',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                              Text(
                                CurrencyFormatter.format(project.totalBudget,
                                    currency: project.currency),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Duration',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                              Text(
                                project.duration,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Client: ${project.client?.name ?? 'Client'}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Freelancer: ${project.freelancer?.name ?? (project.invitedFreelancerEmail.isNotEmpty ? project.invitedFreelancerEmail : 'Pending Invite')}',
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Agreement Box
                if (agreement != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: agreement.isMutuallyAccepted
                          ? AppColors.successLight
                          : AppColors.warningLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: agreement.isMutuallyAccepted
                            ? AppColors.success.withAlpha(80)
                            : AppColors.warning.withAlpha(80),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  agreement.isMutuallyAccepted
                                      ? Icons.verified_user_rounded
                                      : Icons.handshake_outlined,
                                  color: agreement.isMutuallyAccepted
                                      ? AppColors.success
                                      : AppColors.warning,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  agreement.isMutuallyAccepted
                                      ? 'Mutually Accepted Agreement'
                                      : 'Contract Agreement',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: agreement.isMutuallyAccepted
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                            if (agreement.isMutuallyAccepted)
                              TextButton(
                                onPressed: () => _showAgreementSnapshot(agreement),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('View Snapshot',
                                    style: TextStyle(fontSize: 11)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          agreement.terms,
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                        if (agreement.freelancerChangeRequest.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Freelancer Note: "${agreement.freelancerChangeRequest}"',
                              style: const TextStyle(
                                  fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                        if (needsFreelancerAcceptance) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      _respondToAgreementDialog('request_changes'),
                                  child: const Text('Request Changes'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _respondToAgreementDialog('accept'),
                                  child: const Text('Accept Agreement'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Milestones Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Milestones & Escrow Phases',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${project.milestones.length} Phases',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Milestones List
                ...project.milestones.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final milestone = entry.value;
                  return _buildMilestoneTile(
                      context, idx + 1, milestone, isClient, isFreelancer);
                }),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneTile(BuildContext context, int index,
      MilestoneModel milestone, bool isClient, bool isFreelancer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: milestone.isApproved
              ? const Color(0xFF0284C7).withAlpha(100)
              : (milestone.isPaid ? AppColors.success.withAlpha(100) : AppColors.cardBorder),
          width: (milestone.isApproved || milestone.isPaid) ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MilestoneDetailScreen(
                projectId: widget.projectId,
                milestoneId: milestone.id,
              ),
            ),
          ).then((_) => _loadProject());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Phase $index',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      milestone.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(milestone.amount,
                        currency: milestone.currency),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                milestone.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(status: milestone.status),
                  Row(
                    children: [
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ],
              ),

              // Contextual Action Buttons
              if (isClient && milestone.isApproved) ...[
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Pay via PayPal Sandbox',
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
                        onPaymentSuccess: _loadProject,
                      ),
                    );
                  },
                ),
              ] else if (isFreelancer &&
                  (milestone.isInProgress || milestone.isNeedsRevision)) ...[
                const SizedBox(height: 12),
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
                        onSubmitSuccess: _loadProject,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
