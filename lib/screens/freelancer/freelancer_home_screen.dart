import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/project_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/project_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/sandbox_banner.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import '../payments/receipt_detail_screen.dart';
import '../projects/project_detail_screen.dart';

class FreelancerHomeScreen extends StatefulWidget {
  const FreelancerHomeScreen({super.key});

  @override
  State<FreelancerHomeScreen> createState() => _FreelancerHomeScreenState();
}

class _FreelancerHomeScreenState extends State<FreelancerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final projProvider = context.read<ProjectProvider>();
    final dashProvider = context.read<DashboardProvider>();
    await Future.wait([
      projProvider.fetchProjects(),
      dashProvider.fetchStats('freelancer'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dash = context.watch<DashboardProvider>();
    final proj = context.watch<ProjectProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // Sandbox Banner
              const SliverToBoxAdapter(child: SandboxBanner()),

              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Freelancer Workspace',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.user?.name ?? 'Alex Rivera',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.code_rounded,
                                size: 14, color: Color(0xFF0369A1)),
                            SizedBox(width: 4),
                            Text(
                              'FREELANCER',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0369A1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Notifications / Action Items
              if (dash.freelancerRecentNotifications.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      children: dash.freelancerRecentNotifications.map((notif) {
                        final type = notif['type'] ?? 'info';
                        Color bg = AppColors.primaryLight;
                        Color text = AppColors.primary;
                        IconData icon = Icons.info_outline;

                        if (type == 'warning') {
                          bg = AppColors.warningLight;
                          text = AppColors.warning;
                          icon = Icons.warning_amber_rounded;
                        } else if (type == 'success') {
                          bg = AppColors.successLight;
                          text = AppColors.success;
                          icon = Icons.verified_rounded;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: text.withAlpha(50)),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, color: text, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notif['title'] ?? 'Notification',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: text,
                                      ),
                                    ),
                                    Text(
                                      notif['message'] ?? '',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: text.withAlpha(200),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              // Earnings & Milestone Metrics
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Deliveries & Payment Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Sandbox Paid',
                              value: CurrencyFormatter.formatCompact(
                                  dash.freelancerTotalPaidSandbox),
                              icon: Icons.payments_rounded,
                              iconColor: AppColors.success,
                              iconBgColor: AppColors.successLight,
                              subtitle: 'Test funds received',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'Active Milestones',
                              value: '${dash.freelancerActiveMilestones}',
                              icon: Icons.play_arrow_rounded,
                              iconColor: AppColors.primary,
                              iconBgColor: AppColors.primaryLight,
                              subtitle: 'In progress',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Revision Requests',
                              value: '${dash.freelancerRevisionRequests}',
                              icon: Icons.replay_rounded,
                              iconColor: AppColors.error,
                              iconBgColor: AppColors.errorLight,
                              subtitle: 'Needs action',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'Approved Work',
                              value: '${dash.freelancerApprovedWork}',
                              icon: Icons.task_alt_rounded,
                              iconColor: const Color(0xFF0284C7),
                              iconBgColor: const Color(0xFFF0F9FF),
                              subtitle: 'Milestones signed off',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Assigned Projects Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Assigned Projects',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        '${proj.projects.length} Contracts',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Projects List
              if (proj.isLoading && proj.projects.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingIndicator(message: 'Loading assigned projects...'),
                )
              else if (proj.projects.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No Assigned Projects',
                    message:
                        'When clients invite or assign you to contracts, they will appear here with milestones and agreements.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final project = proj.projects[index];
                        return _buildFreelancerProjectCard(context, project);
                      },
                      childCount: proj.projects.length,
                    ),
                  ),
                ),

              // Recent Payment Receipts Section
              if (dash.freelancerPaymentHistory.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: const Text(
                      'Recent PayPal Sandbox Receipts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final t = dash.freelancerPaymentHistory[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReceiptDetailScreen(transaction: t),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.receipt_long_rounded,
                                      color: AppColors.success, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.milestoneTitle,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Receipt: ${t.receiptId} • ${DateFormatter.formatShort(t.paidAt)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '+${CurrencyFormatter.format(t.amount, currency: t.currency)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    const Text(
                                      'PAID (TEST)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: dash.freelancerPaymentHistory.length,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreelancerProjectCard(BuildContext context, ProjectModel project) {
    final needsAgreement = !project.agreement!.freelancerAccepted;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: needsAgreement ? AppColors.warning : AppColors.cardBorder,
          width: needsAgreement ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(projectId: project.id),
            ),
          ).then((_) => _loadData());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (needsAgreement) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.pending_actions_rounded, size: 16, color: AppColors.warning),
                      SizedBox(width: 6),
                      Text(
                        'Agreement Pending Your Review & Acceptance',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.category,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          project.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: project.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              // Milestone counts
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${project.milestones.length} Milestones',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${project.paidMilestonesCount} Paid',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Client: ${project.client?.name ?? 'Client'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    CurrencyFormatter.format(project.totalBudget, currency: project.currency),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
