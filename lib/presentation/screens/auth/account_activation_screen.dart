import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme_config.dart';
import '../../widgets/common/buttons.dart';

/// Account Activation Confirmation Screen
class AccountActivationScreen extends StatefulWidget {
  const AccountActivationScreen({Key? key}) : super(key: key);

  @override
  State<AccountActivationScreen> createState() => _AccountActivationScreenState();
}

class _AccountActivationScreenState extends State<AccountActivationScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: CoopvestColors.success.withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Center(
                  child: Icon(
                    Icons.check_circle,
                    size: 80,
                    color: CoopvestColors.success,
                  ),
                ),
              )
                  .animate()
                  .scale(
                    duration: const Duration(milliseconds: 600),
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                  )
                  .fadeIn(),

              const SizedBox(height: 32),

              // Success Title
              Text(
                'Account Created Successfully!',
                textAlign: TextAlign.center,
                style: CoopvestTypography.displaySmall.copyWith(
                  color: CoopvestColors.darkGray,
                ),
              )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 400))
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 16),

              // Success Message
              Text(
                'Your Coopvest account is ready to use',
                textAlign: TextAlign.center,
                style: CoopvestTypography.bodyMedium.copyWith(
                  color: CoopvestColors.mediumGray,
                  height: 1.6,
                ),
              )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 500))
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 32),

              // Confirmation Details
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CoopvestColors.veryLightGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CoopvestColors.lightGray),
                ),
                child: Column(
                  children: [
                    _buildConfirmationItem(
                      icon: Icons.check_circle_outline,
                      title: 'Account Created',
                      subtitle: 'Your account has been successfully created',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: CoopvestColors.lightGray,
                    ),
                    const SizedBox(height: 16),
                    _buildConfirmationItem(
                      icon: Icons.verified_user_outlined,
                      title: 'Salary Deduction Consent',
                      subtitle: 'Your consent has been recorded and logged',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: CoopvestColors.lightGray,
                    ),
                    const SizedBox(height: 16),
                    _buildConfirmationItem(
                      icon: Icons.info_outline,
                      title: 'Important Notice',
                      subtitle: 'Loans are subject to eligibility and guarantor approval',
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 600))
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 32),

              // Next Steps
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CoopvestColors.primary.withAlpha((255 * 0.05).toInt()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CoopvestColors.primary.withAlpha((255 * 0.2).toInt()),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Steps',
                      style: CoopvestTypography.labelLarge.copyWith(
                        color: CoopvestColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNextStep('1', 'Log in to your account'),
                    const SizedBox(height: 8),
                    _buildNextStep('2', 'Complete KYC verification'),
                    const SizedBox(height: 8),
                    _buildNextStep('3', 'Set up biometric login'),
                    const SizedBox(height: 8),
                    _buildNextStep('4', 'Make your first contribution'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Login Button
              PrimaryButton(
                label: 'Go to Login',
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                width: double.infinity,
              ),

              const SizedBox(height: 16),

              // Auto-redirect message
              Text(
                'Redirecting to login in 3 seconds...',
                textAlign: TextAlign.center,
                style: CoopvestTypography.bodySmall.copyWith(
                  color: CoopvestColors.mediumGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: CoopvestColors.success,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: CoopvestTypography.labelLarge.copyWith(
                  color: CoopvestColors.darkGray,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: CoopvestTypography.bodySmall.copyWith(
                  color: CoopvestColors.mediumGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: CoopvestColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: CoopvestTypography.bodySmall.copyWith(
            color: CoopvestColors.darkGray,
          ),
        ),
      ],
    );
  }
}
