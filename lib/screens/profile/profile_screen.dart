import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditProfile(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.name);
    final bioCtrl = TextEditingController(text: user.bio);
    final skillsCtrl = TextEditingController(text: user.skills.join(', '));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Bio / Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: skillsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Skills (comma separated)',
                  hintText: 'Flutter, Node.js, AI, PayPal',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final skills = skillsCtrl.text
                  .split(',')
                  .map((s) => s.trim())
                  .filter((s) => s.isNotEmpty)
                  .toList();

              await auth.updateProfile(
                name: nameCtrl.text.trim(),
                bio: bioCtrl.text.trim(),
                skills: skills,
              );

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showServerSettings(BuildContext context) {
    final hostController = TextEditingController(
      text: ApiConstants.customHost.isEmpty
          ? ApiConstants.baseUrl
          : ApiConstants.customHost,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backend API Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set host URL (e.g. http://192.168.1.160:3000 for Android phone or http://10.0.2.2:3000 for emulator):',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hostController,
              decoration:
                  const InputDecoration(hintText: 'http://localhost:3000'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              ApiConstants.customHost = '';
              await StorageService.saveCustomHost('');
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reset to default backend host')),
                );
              }
            },
            child: const Text('Reset Default'),
          ),
          ElevatedButton(
            onPressed: () async {
              ApiConstants.customHost = hostController.text.trim();
              await StorageService.saveCustomHost(ApiConstants.customHost);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Server host updated: ${ApiConstants.customHost}'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditProfile(context),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Name & Email
              Text(
                user?.name ?? 'User',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              // Role Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: user?.isClient == true
                      ? AppColors.primaryLight
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user?.isClient == true ? 'CLIENT ACCOUNT' : 'FREELANCER ACCOUNT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: user?.isClient == true
                        ? AppColors.primary
                        : const Color(0xFF0369A1),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bio Card
              if (user?.bio.isNotEmpty == true) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user!.bio,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Skills Chip List
              if (user?.skills.isNotEmpty == true) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Skills & Specialties',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user!.skills.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Hackathon Architecture Specs Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.workspace_premium_rounded,
                            color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'PayPal AI Hackathon 2026',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'TrustPay AI combines Google Gemini structured milestone extraction & verification with PayPal Sandbox Orders v2 server-side escrow release.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Server Settings Action
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                leading:
                    const Icon(Icons.dns_rounded, color: AppColors.primary),
                title: const Text('Backend API Server Host',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  ApiConstants.baseUrl,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showServerSettings(context),
              ),
              const SizedBox(height: 24),

              // Sign Out Button
              CustomButton(
                text: 'Sign Out',
                icon: Icons.logout_rounded,
                isOutlined: true,
                color: AppColors.error,
                textColor: AppColors.error,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text(
                          'Are you sure you want to sign out of TrustPay AI?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error),
                          onPressed: () {
                            Navigator.pop(ctx);
                            auth.logout();
                          },
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

extension FilterExt<T> on Iterable<T> {
  Iterable<T> filter(bool Function(T) test) => where(test);
}
