import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/transaction_model.dart';
import '../../services/payment_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/sandbox_banner.dart';
import 'receipt_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await PaymentService.getTransactions();
      setState(() {
        _transactions = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaction Receipts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SandboxBanner(),
            Expanded(
              child: _isLoading
                  ? const LoadingIndicator(message: 'Loading payment history...')
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Failed to load transactions: $_error'),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _loadTransactions,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _transactions.isEmpty
                          ? const EmptyState(
                              icon: Icons.receipt_long_rounded,
                              title: 'No Transactions Yet',
                              message:
                                  'When milestones are approved and paid through PayPal Sandbox, verified receipts will appear here.',
                            )
                          : RefreshIndicator(
                              onRefresh: _loadTransactions,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                itemCount: _transactions.length,
                                itemBuilder: (context, index) {
                                  final t = _transactions[index];
                                  return _buildTransactionCard(context, t);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              builder: (_) => ReceiptDetailScreen(transaction: t),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t.receiptId,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 12, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'COMPLETED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                t.milestoneTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Project: ${t.projectTitle}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormatter.formatWithTime(t.paidAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(t.amount, currency: t.currency),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
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
