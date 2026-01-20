import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme_config.dart';
import '../../../data/models/referral_models.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/referral_provider.dart';
import '../../../presentation/widgets/common/buttons.dart';
import '../../../presentation/widgets/common/cards.dart';
import 'referral_sharing_screen.dart';

/// Referral Dashboard Screen
/// Shows user's referral code, stats, and tier progress
class ReferralDashboardScreen extends ConsumerWidget {
  const ReferralDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralState = ref.watch(referralProvider);
    final referralNotifier = ref.read(referralProvider.notifier);
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? 'User';

    // Load data on first build
    ref.listen<ReferralState>(referralProvider, (previous, current) {
      if (previous?.status == ReferralStatus.initial && current.status != ReferralStatus.initial) {
        // Data loaded
      }
    });

    // Initial load
    if (referralState.status == ReferralStatus.initial) {
      Future.microtask(() {
        referralNotifier.loadReferralSummary();
        referralNotifier.loadReferralCode();
        referralNotifier.loadReferrals();
      });
    }

    final summary = referralState.summary;
    final tierProgress = referralNotifier.getTierProgress();
    final referralCode = referralState.referralCode ?? 'LOADING...';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'My Referrals',
          style: CoopvestTypography.headlineLarge.copyWith(
            color: CoopvestColors.darkGray,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: CoopvestColors.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ReferralSharingScreen(
                    referralCode: referralCode,
                    userName: userName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Referral Code Card
              _buildReferralCodeCard(context, referralCode, ref),
              const SizedBox(height: 24),

              // Tier Progress Card
              _buildTierProgressCard(tierProgress),
              const SizedBox(height: 24),

              // Stats Cards
              _buildStatsRow(summary),
              const SizedBox(height: 24),

              // How It Works Section
              _buildHowItWorksSection(),
              const SizedBox(height: 24),

              // Recent Referrals
              if (referralState.referrals.isNotEmpty) ...[
                _buildRecentReferralsSection(context, referralState.referrals),
                const SizedBox(height: 24),
              ],

              // Share Button
              PrimaryButton(
                label: 'Share My Referral Code',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ReferralSharingScreen(
                        referralCode: referralCode,
                        userName: userName,
                      ),
                    ),
                  );
                },
                width: double.infinity,
                icon: Icon(Icons.share),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferralCodeCard(BuildContext context, String referralCode, WidgetRef ref) {
    return AppCard(
      backgroundColor: CoopvestColors.primary.withAlpha((255 * 0.05).toInt()),
      border: Border.all(color: CoopvestColors.primary.withAlpha((255 * 0.2).toInt())),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.card_giftcard, color: CoopvestColors.primary, size: 28),
              const SizedBox(width: 8),
              Text(
                'Your Referral Code',
                style: CoopvestTypography.titleMedium.copyWith(
                  color: CoopvestColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CoopvestColors.primary.withAlpha((255 * 0.3).toInt())),
            ),
            child: Text(
              referralCode,
              style: CoopvestTypography.headlineLarge.copyWith(
                color: CoopvestColors.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SecondaryButton(
                label: 'Copy',
                onPressed: () {
                  _copyToClipboard(context, referralCode);
                },
                icon: Icon(Icons.copy),
              ),
              const SizedBox(width: 12),
              SecondaryButton(
                label: 'Share QR',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ReferralSharingScreen(
                        referralCode: referralCode,
                        userName: ref.read(currentUserProvider)?.name ?? 'User',
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.qr_code),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierProgressCard(TierProgress tierProgress) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Tier',
                style: CoopvestTypography.titleMedium.copyWith(
                  color: CoopvestColors.darkGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getTierColor(tierProgress.tierName),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tierProgress.tierName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: tierProgress.progress,
              minHeight: 12,
              backgroundColor: CoopvestColors.veryLightGray,
              valueColor: AlwaysStoppedAnimation<Color>(_getTierColor(tierProgress.tierName)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${tierProgress.currentTier.toStringAsFixed(0)}% discount',
                style: CoopvestTypography.bodySmall.copyWith(
                  color: CoopvestColors.mediumGray,
                ),
              ),
              if (!tierProgress.isMaxTier)
                Text(
                  '${tierProgress.referralsToNext} more to ${tierProgress.nextTier!.toStringAsFixed(0)}%',
                  style: CoopvestTypography.bodySmall.copyWith(
                    color: CoopvestColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                const Text(
                  'Maximum tier reached!',
                  style: TextStyle(
                    color: CoopvestColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ReferralSummary? summary) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Confirmed',
            '${summary?.confirmedReferrals ?? 0}',
            Icons.check_circle,
            CoopvestColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Pending',
            '${summary?.pendingReferrals ?? 0}',
            Icons.hourglass_empty,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total',
            '${summary?.totalReferrals ?? 0}',
            Icons.people,
            CoopvestColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AppCard(
      backgroundColor: color.withAlpha((255 * 0.1).toInt()),
      border: Border.all(color: color.withAlpha((255 * 0.2).toInt())),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
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

  Widget _buildHowItWorksSection() {
    return AppCard(
      backgroundColor: CoopvestColors.veryLightGray,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How It Works',
            style: CoopvestTypography.titleMedium.copyWith(
              color: CoopvestColors.darkGray,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildHowItWorksStep(1, 'Share your referral code'),
          _buildHowItWorksStep(2, 'Friend completes KYC & saves for 3 months'),
          _buildHowItWorksStep(3, 'Earn interest reduction on your loan'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CoopvestColors.primary.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: CoopvestColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bonus is locked for 30 days after referral confirms',
                    style: CoopvestTypography.bodySmall.copyWith(
                      color: CoopvestColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksStep(int step, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: CoopvestColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: CoopvestTypography.bodyMedium.copyWith(
                color: CoopvestColors.darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReferralsSection(BuildContext context, List<Referral> referrals) {
    final recentReferrals = referrals.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Referrals',
              style: CoopvestTypography.titleMedium.copyWith(
                color: CoopvestColors.darkGray,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // View all referrals
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recentReferrals.map((referral) => _buildReferralItem(context, referral)),
      ],
    );
  }

  Widget _buildReferralItem(BuildContext context, Referral referral) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getReferralStatusColor(referral).withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                _getReferralStatusIcon(referral),
                color: _getReferralStatusColor(referral),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    referral.referredName,
                    style: CoopvestTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: CoopvestColors.darkGray,
                    ),
                  ),
                  Text(
                    _getReferralStatusText(referral),
                    style: CoopvestTypography.bodySmall.copyWith(
                      color: _getReferralStatusColor(referral),
                    ),
                  ),
                ],
              ),
            ),
            if (referral.tierBonusPercent > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CoopvestColors.success.withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${referral.tierBonusPercent.toStringAsFixed(0)}% OFF',
                  style: CoopvestTypography.labelSmall.copyWith(
                    color: CoopvestColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(String tierName) {
    switch (tierName) {
      case 'Gold': return const Color(0xFFFFD700);
      case 'Silver': return const Color(0xFFC0C0C0);
      case 'Bronze': return const Color(0xFFCD7F32);
      default: return CoopvestColors.mediumGray;
    }
  }

  Color _getReferralStatusColor(Referral referral) {
    if (referral.isFlagged) return CoopvestColors.error;
    if (referral.bonusConsumed) return CoopvestColors.info;
    if (referral.confirmed) return CoopvestColors.success;
    if (referral.kycVerified) return Colors.blue;
    return Colors.orange;
  }

  IconData _getReferralStatusIcon(Referral referral) {
    if (referral.isFlagged) return Icons.flag;
    if (referral.bonusConsumed) return Icons.check_circle;
    if (referral.confirmed) return Icons.check_circle_outline;
    if (referral.kycVerified) return Icons.verified;
    return Icons.hourglass_empty;
  }

  String _getReferralStatusText(Referral referral) {
    if (referral.isFlagged) return 'Flagged: ${referral.flaggedReason}';
    if (referral.bonusConsumed) return 'Bonus used';
    if (referral.confirmed) return referral.lockInEndDate != null && DateTime.now().isBefore(referral.lockInEndDate!)
        ? 'In lock-in period'
        : 'Bonus available';
    if (referral.kycVerified) return 'KYC complete, savings pending';
    return 'Awaiting KYC';
  }

  void _copyToClipboard(BuildContext context, String text) {
    // In a real app, use Clipboard.setData
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Referral code copied: $text'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
