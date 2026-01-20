import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../config/theme_config.dart';
import '../../../presentation/providers/referral_provider.dart';

/// Referral Sharing Screen
/// Shows QR code and sharing options for referral code
class ReferralSharingScreen extends ConsumerWidget {
  final String referralCode;
  final String userName;

  const ReferralSharingScreen({
    super.key,
    required this.referralCode,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralState = ref.watch(referralProvider);
    final shareLink = referralState.shareLink?.shareLink ??
        'https://coopvest.app/register?ref=$referralCode';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: CoopvestColors.darkGray),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Share Your Code',
          style: CoopvestTypography.headlineLarge.copyWith(
            color: CoopvestColors.darkGray,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // QR Code Section
              _buildQRCodeSection(shareLink),
              const SizedBox(height: 24),

              // Referral Code Display
              _buildReferralCodeDisplay(),
              const SizedBox(height: 32),

              // Share Link Section
              _buildShareLinkSection(context, shareLink),
              const SizedBox(height: 32),

              // Social Sharing
              _buildSocialSharingSection(context, shareLink),
              const SizedBox(height: 32),

              // Referral Message Template
              _buildMessageTemplate(context, referralCode, userName),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRCodeSection(String shareLink) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CoopvestColors.primary.withAlpha((255 * 0.1).toInt()),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          QrImageView(
            data: shareLink,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF1B5E20),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scan to join Coopvest Africa',
            style: CoopvestTypography.bodyMedium.copyWith(
              color: CoopvestColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: CoopvestColors.veryLightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Code: ',
            style: CoopvestTypography.bodyMedium.copyWith(
              color: CoopvestColors.mediumGray,
            ),
          ),
          Text(
            referralCode,
            style: CoopvestTypography.headlineSmall.copyWith(
              color: CoopvestColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: referralCode));
              // Show snackbar
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CoopvestColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.copy,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareLinkSection(BuildContext context, String shareLink) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share Link',
          style: CoopvestTypography.titleMedium.copyWith(
            color: CoopvestColors.darkGray,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: CoopvestColors.veryLightGray,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CoopvestColors.lightGray),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  shareLink,
                  style: CoopvestTypography.bodySmall.copyWith(
                    color: CoopvestColors.darkGray,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: shareLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Link copied: $shareLink')),
                  );
                },
                child: const Text('Copy'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialSharingSection(BuildContext context, String shareLink) {
    final message = _getReferralMessage(referralCode, userName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share via',
          style: CoopvestTypography.titleMedium.copyWith(
            color: CoopvestColors.darkGray,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildShareButton(
              icon: Icons.message,
              label: 'SMS',
              color: Colors.blue,
              onTap: () => _shareViaSMS(context, message),
            ),
            _buildShareButton(
              icon: Icons.email,
              label: 'Email',
              color: Colors.red,
              onTap: () => _shareViaEmail(context, message),
            ),
            _buildShareButton(
              icon: Icons.link,
              label: 'Copy Link',
              color: Colors.purple,
              onTap: () => _copyLink(context, shareLink),
            ),
            _buildShareButton(
              icon: Icons.share,
              label: 'More',
              color: CoopvestColors.primary,
              onTap: () => _shareMore(context, message),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: CoopvestTypography.bodySmall.copyWith(
              color: CoopvestColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTemplate(BuildContext context, String code, String name) {
    final message = _getReferralMessage(code, name);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoopvestColors.veryLightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Message Template',
                style: CoopvestTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: CoopvestColors.darkGray,
                ),
              ),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: message));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message copied!')),
                  );
                },
                child: const Text('Copy'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: CoopvestTypography.bodySmall.copyWith(
                color: CoopvestColors.darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getReferralMessage(String code, String name) {
    return "Hey! Join Coopvest Africa using my referral code $code and get exclusive benefits on your loans. Download the app: https://coopvest.app/register?ref=$code";
  }

  void _shareViaSMS(BuildContext context, String message) {
    // In a real app, use url_launcher or share_plus
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening SMS app...')),
    );
  }

  void _shareViaEmail(BuildContext context, String message) {
    // In a real app, use url_launcher or share_plus
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening email app...')),
    );
  }

  void _copyLink(BuildContext context, String link) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard!')),
    );
  }

  void _shareMore(BuildContext context, String message) {
    // In a real app, use share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening share sheet...')),
    );
  }
}
