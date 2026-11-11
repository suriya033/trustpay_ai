import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/milestone_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/project_provider.dart';
import '../payments/receipt_detail_screen.dart';

class PayPalCheckoutModal extends StatefulWidget {
  final String projectId;
  final MilestoneModel milestone;
  final VoidCallback onPaymentSuccess;

  const PayPalCheckoutModal({
    super.key,
    required this.projectId,
    required this.milestone,
    required this.onPaymentSuccess,
  });

  @override
  State<PayPalCheckoutModal> createState() => _PayPalCheckoutModalState();
}

class _PayPalCheckoutModalState extends State<PayPalCheckoutModal> {
  bool _isProcessing = false;
  String _statusText = '';
  Map<String, dynamic>? _paymentResult;

  Future<void> _handlePayPalPayment() async {
    setState(() {
      _isProcessing = true;
      _statusText = 'Contacting PayPal Sandbox REST API (Orders v2)...';
    });

    final projProvider = context.read<ProjectProvider>();

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _statusText = 'Creating PayPal Order & Securing Escrow...');

      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _statusText = 'Verifying Server-Side Capture & Receipt ID...');

      final result = await projProvider.processPayPalPayment(
        projectId: widget.projectId,
        milestoneId: widget.milestone.id,
      );

      setState(() {
        _isProcessing = false;
        _paymentResult = result;
      });

      if (result != null) {
        widget.onPaymentSuccess();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusText = 'Payment failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PayPal Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.paypalBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PayPal',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SANDBOX TEST',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_paymentResult != null) ...[
            // Payment Success View
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.successLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Payment Captured Successfully!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Milestone escrow released to freelancer via PayPal Sandbox.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receipt ID: ${_paymentResult!['receiptId'] ?? 'TP-REC-2026'}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Amount Released: ${CurrencyFormatter.format(widget.milestone.amount)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Done'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_paymentResult!['transaction'] != null)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReceiptDetailScreen(
                                    transaction: TransactionModel.fromJson(
                                        _paymentResult!['transaction']),
                                  ),
                                ),
                              );
                            },
                            child: const Text('View Full Receipt'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Checkout Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Milestone to Release:',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.milestone.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payment Release:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(widget.milestone.amount,
                            currency: widget.milestone.currency),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_isProcessing) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // PayPal Styled Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handlePayPalPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.paypalGold,
                  foregroundColor: const Color(0xFF111111),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Pay with ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF003087),
                      ),
                    ),
                    const Text(
                      'PayPal',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF003087),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${CurrencyFormatter.format(widget.milestone.amount)})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF003087),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Uses PayPal Orders v2 Sandbox. Funds are simulated in test environment.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
