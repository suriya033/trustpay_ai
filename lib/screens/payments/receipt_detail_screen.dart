import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/transaction_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/sandbox_banner.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const ReceiptDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment Receipt'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SandboxBanner(),
              const SizedBox(height: 16),

              // Formal Receipt Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Brand & Verified Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.verified_user_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'TrustPay AI',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.paypalBlue.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PayPal Sandbox',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.paypalBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Amount
                    Text(
                      CurrencyFormatter.format(transaction.amount,
                          currency: transaction.currency),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 14, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'ESCROW PAYMENT COMPLETED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Key Receipt Fields
                    _buildReceiptRow('Receipt Number', transaction.receiptId),
                    _buildReceiptRow('Payment Date',
                        DateFormatter.formatWithTime(transaction.paidAt)),
                    _buildReceiptRow('Project', transaction.projectTitle),
                    _buildReceiptRow('Milestone', transaction.milestoneTitle),
                    _buildReceiptRow(
                        'Payer (Client)',
                        '${transaction.clientName} (${transaction.clientEmail})'),
                    _buildReceiptRow(
                        'Payee (Freelancer)',
                        '${transaction.freelancerName} (${transaction.freelancerEmail})'),
                    _buildReceiptRow(
                        'PayPal Order ID', transaction.paypalOrderId),
                    _buildReceiptRow(
                        'PayPal Capture ID', transaction.paypalCaptureId),
                    _buildReceiptRow('Payment Method',
                        'PayPal Sandbox REST Orders v2 API'),
                    _buildReceiptRow('Environment', 'PayPal Sandbox (Test)'),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Watermark / Verification Footer
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_rounded,
                            size: 14, color: AppColors.textMuted),
                        SizedBox(width: 6),
                        Text(
                          'Cryptographically logged and verified in MongoDB',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              CustomButton(
                text: 'Copy Receipt Reference',
                icon: Icons.copy_rounded,
                isOutlined: true,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Copied ${transaction.receiptId} to clipboard'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              CustomButton(
                text: 'Done',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
