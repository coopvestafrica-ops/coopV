import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme_config.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../data/models/wallet_models.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/wallet_provider.dart';
import '../../../presentation/widgets/common/cards.dart';
import '../loan/loan_dashboard_screen.dart';
import '../wallet/wallet_dashboard_screen.dart';
import '../savings/savings_goals_screen.dart';
import '../rollover/rollover_eligibility_screen.dart';
import '../loan/qr_scanner_screen.dart';

/// Main Home Dashboard Screen
class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);
    final wallet = walletState.wallet;
    final savingsGoals = walletState.savingsGoals.where((g) => g.status == 'active').toList();
    final recentTransactions = walletState.transactions.take(3).toList();
    
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? 'User';
    final userId = user?.id ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.notifications_none, color: CoopvestColors.darkGray),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: CoopvestColors.darkGray),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: CoopvestTypography.bodyMedium.copyWith(
                  color: CoopvestColors.mediumGray,
                ),
              ),
              Text(
                userName,
                style: CoopvestTypography.headlineLarge.copyWith(
                  color: CoopvestColors.darkGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Savings',
                      '\u20a6${(wallet?.balance ?? 0).formatNumber()}',
                      Icons.savings,
                      CoopvestColors.success,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Active Loans',
                      '1',
                      Icons.account_balance,
                      CoopvestColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Savings Goals',
                      '${savingsGoals.length}',
                      Icons.flag,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Pending',
                      '\u20a6${(wallet?.pendingContributions ?? 0).formatNumber()}',
                      Icons.pending,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildQuickActionsGrid(context, userId, userName),
              const SizedBox(height: 32),
              _buildRolloverSection(context),
              const SizedBox(height: 32),
              if (savingsGoals.isNotEmpty) ...[
                _buildSectionHeader('Savings Goals', () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SavingsGoalsScreen(userId: userId),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                ...savingsGoals.take(2).map((goal) => _buildGoalProgressCard(context, goal)),
                const SizedBox(height: 32),
              ],
              _buildSectionHeader('Recent Activity', () {}),
              const SizedBox(height: 16),
              if (recentTransactions.isEmpty)
                _buildEmptyActivityCard()
              else
                ...recentTransactions.map((txn) => _buildActivityItem(context, txn)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AppCard(
      backgroundColor: color.withAlpha((255 * 0.1).toInt()),
      border: Border.all(color: color.withAlpha((255 * 0.2).toInt())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: CoopvestTypography.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: CoopvestTypography.bodySmall.copyWith(
              color: CoopvestColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, String userId, String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: CoopvestTypography.titleMedium.copyWith(
            color: CoopvestColors.darkGray,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.account_balance_wallet,
                label: 'Wallet',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WalletDashboardScreen(userId: userId, userName: userName),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.savings,
                label: 'Save',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SavingsGoalsScreen(userId: userId),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.request_quote,
                label: 'Loans',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LoanDashboardScreen(
                        userId: userId, 
                        userName: userName, 
                        userPhone: '',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.qr_code_scanner,
                label: 'Scan QR',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => QRScannerScreen(
                        guarantorId: userId,
                        guarantorName: userName,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: CoopvestColors.veryLightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: CoopvestColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: CoopvestTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: CoopvestTypography.titleMedium.copyWith(
            color: CoopvestColors.darkGray,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: const Text('View All'),
        ),
      ],
    );
  }

  Widget _buildGoalProgressCard(BuildContext context, SavingsGoal goal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(goal.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${goal.progressPercentage.toStringAsFixed(0)}%', style: TextStyle(color: CoopvestColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progressPercentage / 100,
                minHeight: 8,
                backgroundColor: CoopvestColors.veryLightGray,
                valueColor: const AlwaysStoppedAnimation<Color>(CoopvestColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\u20a6${goal.currentAmount.formatNumber()} of \u20a6${goal.targetAmount.formatNumber()}',
              style: TextStyle(color: CoopvestColors.mediumGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActivityCard() {
    return AppCard(
      backgroundColor: CoopvestColors.veryLightGray,
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history, color: CoopvestColors.mediumGray, size: 48),
            const SizedBox(height: 8),
            Text(
              'No recent activity',
              style: TextStyle(color: CoopvestColors.mediumGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, Transaction txn) {
    final isCredit = txn.type == 'contribution' || txn.type == 'loan_disbursement' || txn.type == 'refund';
    
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCredit ? CoopvestColors.success.withAlpha((255 * 0.1).toInt()) : CoopvestColors.error.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(10),
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
                Text(txn.description ?? txn.type.replaceAll('_', ' ').capitalize()),
                Text(
                  '${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year}',
                  style: TextStyle(color: CoopvestColors.mediumGray, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}\u20a6${txn.amount.formatNumber()}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCredit ? CoopvestColors.success : CoopvestColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolloverSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Loan Services',
              style: CoopvestTypography.titleMedium.copyWith(
                color: CoopvestColors.darkGray,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _navigateToRolloverEligibility(context),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CoopvestColors.primary,
                  CoopvestColors.primary.withAlpha((255 * 0.8).toInt()),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: CoopvestColors.primary.withAlpha((255 * 0.3).toInt()),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Loan Rollover',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Extend your loan repayment period when you need more time. Eligible if you\'ve repaid at least 50% of your principal.',
                        style: TextStyle(
                          color: Colors.white.withAlpha((255 * 0.9).toInt()),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((255 * 0.2).toInt()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Check Eligibility →',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToRolloverEligibility(BuildContext context) {
    // Navigate to rollover eligibility - the screen will fetch actual data
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RolloverEligibilityScreen(),
      ),
    );
  }
}
