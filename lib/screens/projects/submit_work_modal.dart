import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/milestone_model.dart';
import '../../providers/project_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class SubmitWorkModal extends StatefulWidget {
  final String projectId;
  final MilestoneModel milestone;
  final VoidCallback onSubmitSuccess;

  const SubmitWorkModal({
    super.key,
    required this.projectId,
    required this.milestone,
    required this.onSubmitSuccess,
  });

  @override
  State<SubmitWorkModal> createState() => _SubmitWorkModalState();
}

class _SubmitWorkModalState extends State<SubmitWorkModal> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _githubController = TextEditingController();
  final _demoController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _descController.dispose();
    _githubController.dispose();
    _demoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final projProvider = context.read<ProjectProvider>();
    final submission = await projProvider.submitWork(
      projectId: widget.projectId,
      milestoneId: widget.milestone.id,
      description: _descController.text.trim(),
      githubUrl: _githubController.text.trim(),
      liveDemoUrl: _demoController.text.trim(),
      notes: _notesController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (submission != null) {
      widget.onSubmitSuccess();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Work submitted successfully! You can now request Gemini AI verification.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(projProvider.errorMessage ?? 'Failed to submit work'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Submit Work Evidence',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Milestone: ${widget.milestone.title}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descController,
                label: 'Summary of Completed Work *',
                hint: 'Detail what was implemented and how it satisfies acceptance criteria...',
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().length < 5) {
                    return 'Please describe completed work';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _githubController,
                label: 'GitHub Repository / PR Link',
                hint: 'https://github.com/username/project/pull/1',
                prefixIcon: Icons.code_rounded,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _demoController,
                label: 'Live Demo URL / Preview',
                hint: 'https://demo-app.web.app',
                prefixIcon: Icons.launch_rounded,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _notesController,
                label: 'Implementation Notes / Test Credentials',
                hint: 'e.g. Test login credentials, test API endpoints, instructions',
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Submit for AI & Client Verification',
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
