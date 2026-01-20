import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme_config.dart';

/// KYC Success Screen - Shown when KYC verification is complete
class KYCSuccessScreen extends ConsumerWidget {
  const KYCSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: CoopvestTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: CoopvestTheme.lightTheme.primaryColor.withAlpha((255 * 0.1).toInt()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: CoopvestTheme.lightTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              
              // Success Message
              const Text(
                'KYC Verification Complete!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Your identity verification has been submitted successfully. Our team will review your documents and update your status within 24-48 hours.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // What Next Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: CoopvestTheme.lightTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'What\'s Next?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildNextStep('1', 'Check back later for approval status'),
                    _buildNextStep('2', 'Once approved, you can apply for loans'),
                    _buildNextStep('3', 'Start saving to build your credit history'),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to home/dashboard
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CoopvestTheme.lightTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go to Dashboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: CoopvestTheme.lightTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
