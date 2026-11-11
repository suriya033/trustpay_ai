import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/project_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/project_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/sandbox_banner.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import '../projects/project_detail_screen.dart';
import 'create_project_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
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
      dashProvider.fetchStats('client'),
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
              const SliverToBoxAdapter(
                child: SandboxBanner(),
              ),

              // Header Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.user?.name ?? 'Client',
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
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.business_center_rounded,
                                size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'CLIENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Action Button
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.textInverse,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need a new project?',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Generate milestones & criteria with Gemini AI',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateProjectScreen(),
                              ),
                            ).then((_) => _loadData());
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text('Create',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Fintech Stats Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Escrow & Project Metrics',
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
                              title: 'Total Budget',
                              value: CurrencyFormatter.formatCompact(
                                  dash.clientTotalBudget),
                              icon: Icons.account_balance_wallet_rounded,
                              iconColor: AppColors.primary,
                              iconBgColor: AppColors.primaryLight,
                              subtitle:
                                  '${dash.clientTotalProjects} Projects Total',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'PayPal Paid',
                              value: CurrencyFormatter.formatCompact(
                                  dash.clientCompletedSandboxPayments),
                              icon: Icons.payments_rounded,
                              iconColor: AppColors.success,
                              iconBgColor: AppColors.successLight,
                              subtitle: 'Sandbox Transactions',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Approved Value',
                              value: CurrencyFormatter.formatCompact(
                                  dash.clientApprovedMilestoneValue),
                              icon: Icons.verified_rounded,
                              iconColor: const Color(0xFF0284C7),
                              iconBgColor: const Color(0xFFF0F9FF),
                              subtitle: 'Ready to release',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'Pending Reviews',
                              value: '${dash.clientPendingApprovals}',
                              icon: Icons.hourglass_empty_rounded,
                              iconColor: AppColors.warning,
                              iconBgColor: AppColors.warningLight,
                              subtitle: 'Awaiting your review',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Filter Tabs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Projects',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(context, 'all', 'All'),
                            const SizedBox(width: 6),
                            _buildFilterChip(context, 'active', 'Active'),
                            const SizedBox(width: 6),
                            _buildFilterChip(context, 'pending', 'Pending'),
                            const SizedBox(width: 6),
                            _buildFilterChip(context, 'completed', 'Completed'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Project List or Empty State
              if (proj.isLoading && proj.projects.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingIndicator(message: 'Loading client projects...'),
                )
              else if (proj.projects.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.folder_open_rounded,
                    title: 'No Projects Found',
                    message:
                        'Create your first project and use Google Gemini AI to auto-generate milestones and acceptance criteria.',
                    buttonText: 'Create Project with AI',
                    onButtonPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateProjectScreen(),
                        ),
                      ).then((_) => _loadData());
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final project = proj.projects[index];
                        return _buildProjectCard(context, project);
                      },
                      childCount: proj.projects.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String filterKey, String label) {
    final proj = context.watch<ProjectProvider>();
    final isSelected = proj.currentFilter == filterKey;

    return GestureDetector(
      onTap: () => proj.setFilter(filterKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.textInverse : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectModel project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
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
              const SizedBox(height: 10),
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
              const SizedBox(height: 14),
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${project.paidMilestonesCount} of ${project.milestones.length} Milestones Paid',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${project.progress}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: project.progress / 100,
                      backgroundColor: AppColors.secondaryBackground,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.secondaryBackground,
                        child: const Icon(Icons.person,
                            size: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        project.freelancer?.name ??
                            (project.invitedFreelancerEmail.isNotEmpty
                                ? project.invitedFreelancerEmail
                                : 'Unassigned'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.format(project.totalBudget,
                        currency: project.currency),
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
