import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme_config.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../data/models/wallet_models.dart';
import '../../../presentation/providers/wallet_provider.dart';
import '../../../presentation/widgets/common/cards.dart';

/// Transactions History Screen
class TransactionsHistoryScreen extends ConsumerWidget {
  final String userId;

  const TransactionsHistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);
    final transactions = walletState.transactions;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CoopvestColors.darkGray),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Transaction History',
          style: CoopvestTypography.headlineLarge.copyWith(
            color: CoopvestColors.darkGray,
          ),
        ),
      ),
      body: SafeArea(
        child: transactions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, color: CoopvestColors.mediumGray, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: CoopvestTypography.titleMedium.copyWith(
                        color: CoopvestColors.mediumGray,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final txn = transactions[index];
                  return _buildTransactionItem(context, txn);
                },
              ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction txn) {
    final isCredit = txn.type == 'contribution' || txn.type == 'loan_disbursement' || txn.type == 'refund';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isCredit 
                    ? CoopvestColors.success.withAlpha((255 * 0.1).toInt())
                    : CoopvestColors.error.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isCredit ? CoopvestColors.success : CoopvestColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.description ?? txn.type.replaceAll('_', ' ').capitalize(),
                    style: CoopvestTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_getMonthName(txn.createdAt.month)} ${txn.createdAt.day}, ${txn.createdAt.year}',
                    style: CoopvestTypography.bodySmall.copyWith(
                      color: CoopvestColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isCredit ? '+' : '-'}₦${txn.amount.toStringAsFixed(2)}',
              style: CoopvestTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isCredit ? CoopvestColors.success : CoopvestColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
