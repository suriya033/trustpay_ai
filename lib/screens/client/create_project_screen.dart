import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/user_model.dart';
import '../../providers/project_provider.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetController = TextEditingController(text: '1000');
  final _durationController = TextEditingController(text: '4 weeks');
  final _techReqController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _freelancerEmailController = TextEditingController();

  String _category = 'Web Development';
  final String _currency = 'USD';
  DateTime? _deadline;

  bool _isGeneratingAi = false;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _milestones = [];
  List<UserModel> _availableFreelancers = [];

  final List<String> _categories = [
    'Web Development',
    'Mobile App (Flutter/Android/iOS)',
    'AI / Machine Learning',
    'FinTech & Blockchain',
    'UI/UX Design',
    'DevOps & Cloud',
    'Full-Stack Solution',
  ];

  @override
  void initState() {
    super.initState();
    _loadFreelancers();
  }

  Future<void> _loadFreelancers() async {
    try {
      final list = await AuthService.getFreelancers();
      setState(() {
        _availableFreelancers = list;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _budgetController.dispose();
    _durationController.dispose();
    _techReqController.dispose();
    _instructionsController.dispose();
    _freelancerEmailController.dispose();
    super.dispose();
  }

  double get _totalBudget => double.tryParse(_budgetController.text) ?? 0.0;

  double get _allocatedBudget =>
      _milestones.fold(0.0, (sum, m) => sum + (m['amount'] as num? ?? 0.0));

  bool get _isBudgetMatched =>
      (_totalBudget - _allocatedBudget).abs() < 0.01 && _totalBudget > 0;

  Future<void> _handleGenerateMilestones() async {
    if (_titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty ||
        _totalBudget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Project Title, Description, and Budget first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isGeneratingAi = true);

    try {
      final generated = await AiService.generateMilestones(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _category,
        totalBudget: _totalBudget,
        currency: _currency,
        duration: _durationController.text.trim(),
        technicalRequirements: _techReqController.text.trim(),
        additionalInstructions: _instructionsController.text.trim(),
      );

      setState(() {
        _milestones = generated
            .map((m) => {
                  'title': m.title,
                  'description': m.description,
                  'amount': m.amount,
                  'currency': m.currency,
                  'suggestedDuration': m.suggestedDuration,
                  'deliverables': List<String>.from(m.deliverables),
                  'acceptanceCriteria': List<String>.from(m.acceptanceCriteria),
                  'dependencies': List<String>.from(m.dependencies),
                  'potentialRisks': List<String>.from(m.potentialRisks),
                })
            .toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gemini AI generated ${_milestones.length} structured milestones!',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI Generation Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingAi = false);
    }
  }

  void _addManualMilestone() {
    setState(() {
      final remaining = (_totalBudget - _allocatedBudget).clamp(0.0, _totalBudget);
      _milestones.add({
        'title': 'New Milestone ${_milestones.length + 1}',
        'description': 'Deliverable description',
        'amount': remaining > 0 ? remaining : 100.0,
        'currency': _currency,
        'suggestedDuration': '1 week',
        'deliverables': ['Specific deliverable item'],
        'acceptanceCriteria': ['Measurable acceptance criterion'],
        'dependencies': [],
        'potentialRisks': [],
      });
    });
  }

  void _editMilestoneDialog(int index) {
    final m = _milestones[index];
    final titleCtrl = TextEditingController(text: m['title']);
    final descCtrl = TextEditingController(text: m['description']);
    final amountCtrl = TextEditingController(text: m['amount'].toString());
    final durationCtrl = TextEditingController(text: m['suggestedDuration']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Milestone ${index + 1}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Milestone Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (\$)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: durationCtrl,
                decoration: const InputDecoration(labelText: 'Duration'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _milestones.removeAt(index);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                m['title'] = titleCtrl.text;
                m['description'] = descCtrl.text;
                m['amount'] = double.tryParse(amountCtrl.text) ?? m['amount'];
                m['suggestedDuration'] = durationCtrl.text;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_milestones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate or add milestones before submitting'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (!_isBudgetMatched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Milestone sum (${CurrencyFormatter.format(_allocatedBudget)}) must equal project budget (${CurrencyFormatter.format(_totalBudget)})',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final projProvider = context.read<ProjectProvider>();

    final created = await projProvider.createProject(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _category,
      totalBudget: _totalBudget,
      currency: _currency,
      duration: _durationController.text.trim(),
      deadline: _deadline,
      technicalRequirements: _techReqController.text.trim(),
      additionalInstructions: _instructionsController.text.trim(),
      invitedFreelancerEmail: _freelancerEmailController.text.trim(),
      milestones: _milestones,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project created with AI milestones & proposed to freelancer!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(projProvider.errorMessage ?? 'Failed to create project'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Project with AI'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Google Gemini AI will decompose your requirements into verified milestones, deliverables, and testable criteria.',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                CustomTextField(
                  controller: _titleController,
                  label: 'Project Title *',
                  hint: 'e.g. E-Commerce Mobile App with PayPal',
                  validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
                ),
                const SizedBox(height: 14),

                // Category dropdown
                const Text(
                  'Project Category',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _category,
                      isExpanded: true,
                      items: _categories.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Budget & Currency
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _budgetController,
                        label: 'Total Budget *',
                        hint: '1000',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final num = double.tryParse(v ?? '');
                          if (num == null || num <= 0) return 'Enter budget > 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Currency',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Center(
                              child: Text(
                                'USD (\$)',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Duration & Expected Timeline
                CustomTextField(
                  controller: _durationController,
                  label: 'Expected Duration',
                  hint: 'e.g. 4 weeks, 2 months',
                ),
                const SizedBox(height: 14),

                // Description
                CustomTextField(
                  controller: _descController,
                  label: 'Project Description *',
                  hint: 'Describe goals, core features, and outcomes...',
                  maxLines: 3,
                  validator: (v) => (v == null || v.length < 10) ? 'Enter at least 10 chars' : null,
                ),
                const SizedBox(height: 14),

                // Technical Requirements
                CustomTextField(
                  controller: _techReqController,
                  label: 'Technical Requirements',
                  hint: 'e.g. Flutter Material 3, Node.js REST API, MongoDB, PayPal SDK',
                  maxLines: 2,
                ),
                const SizedBox(height: 14),

                // Additional Instructions
                CustomTextField(
                  controller: _instructionsController,
                  label: 'Additional Instructions',
                  hint: 'e.g. Weekly sprint demos, strict test coverage...',
                ),
                const SizedBox(height: 14),

                // Invite Freelancer
                const Text(
                  'Assign / Invite Freelancer',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                if (_availableFreelancers.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        hint: const Text('Select registered freelancer', style: TextStyle(fontSize: 13)),
                        isExpanded: true,
                        items: _availableFreelancers.map((f) {
                          return DropdownMenuItem(
                            value: f.email,
                            child: Text('${f.name} (${f.email})', style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _freelancerEmailController.text = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
                CustomTextField(
                  controller: _freelancerEmailController,
                  label: 'Or enter Freelancer Email',
                  hint: 'freelancer@trustpay.ai',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),

                // AI Generate Button
                CustomButton(
                  text: 'Generate Milestones with AI',
                  icon: Icons.auto_awesome_rounded,
                  isLoading: _isGeneratingAi,
                  color: AppColors.primary,
                  onPressed: _handleGenerateMilestones,
                ),
                const SizedBox(height: 24),

                // Milestones Review & Editor Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Milestones Breakdown',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_milestones.length} milestones allocated',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _addManualMilestone,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Milestone', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Budget Balancing Status Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isBudgetMatched ? AppColors.successLight : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isBudgetMatched ? AppColors.success.withAlpha(50) : AppColors.warning.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isBudgetMatched ? Icons.check_circle_rounded : Icons.info_outline,
                            size: 16,
                            color: _isBudgetMatched ? AppColors.success : AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isBudgetMatched ? 'Budget Balanced' : 'Budget Discrepancy',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _isBudgetMatched ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${CurrencyFormatter.format(_allocatedBudget)} / ${CurrencyFormatter.format(_totalBudget)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _isBudgetMatched ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Milestone Cards List
                if (_milestones.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.format_list_bulleted_add, size: 36, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text(
                          'No milestones yet',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap "Generate Milestones with AI" to let Gemini AI draft sequential phases and criteria.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  ..._milestones.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final m = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Phase ${idx + 1}: ${m['title']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    CurrencyFormatter.format(m['amount']),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    onPressed: () => _editMilestoneDialog(idx),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            m['description'] ?? '',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          if (m['deliverables'] is List && (m['deliverables'] as List).isNotEmpty) ...[
                            const Text(
                              'Deliverables:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            ...(m['deliverables'] as List).take(2).map((d) => Padding(
                                  padding: const EdgeInsets.only(left: 4, top: 2),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                                      Expanded(
                                          child: Text(d.toString(),
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                                    ],
                                  ),
                                )),
                          ],
                          const SizedBox(height: 6),
                          if (m['acceptanceCriteria'] is List && (m['acceptanceCriteria'] as List).isNotEmpty) ...[
                            const Text(
                              'Acceptance Criteria:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            ...(m['acceptanceCriteria'] as List).take(2).map((c) => Padding(
                                  padding: const EdgeInsets.only(left: 4, top: 2),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check, size: 12, color: AppColors.success),
                                      const SizedBox(width: 4),
                                      Expanded(
                                          child: Text(c.toString(),
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                                    ],
                                  ),
                                )),
                          ],
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 24),
                CustomButton(
                  text: 'Create Project & Propose Agreement',
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
