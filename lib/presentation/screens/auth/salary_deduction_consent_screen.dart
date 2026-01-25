import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme_config.dart';
import '../../../core/services/api_service.dart';
import '../../widgets/common/buttons.dart';

/// Salary Deduction & Loan Recovery Consent Screen - Real API Integration
class SalaryDeductionConsentScreen extends ConsumerStatefulWidget {
  final Map<String, String> registrationData;

  const SalaryDeductionConsentScreen({
    Key? key,
    required this.registrationData,
  }) : super(key: key);

  @override
  ConsumerState<SalaryDeductionConsentScreen> createState() =>
      _SalaryDeductionConsentScreenState();
}

class _SalaryDeductionConsentScreenState
    extends ConsumerState<SalaryDeductionConsentScreen> {
  bool _agreeToConsent = false;
  bool _isSubmitting = false;

  final ApiService _apiService = ApiService();

  Future<void> _submitConsent() async {
    if (!_agreeToConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please read and accept the consent'),
          backgroundColor: CoopvestColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Call API to submit consent
      final response = await _apiService.post(
        '/auth/salary-consent',
        data: {
          'memberId': widget.registrationData['memberId'] ?? '',
          'consent': _agreeToConsent,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response['success'] == true) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/account-activation');
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to submit consent');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: CoopvestColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Consent & Authorization',
          style: CoopvestTypography.headlineLarge.copyWith(
            color: CoopvestColors.darkGray,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CoopvestColors.warning.withAlpha((255 * 0.1).toInt()),
                  border: Border.all(color: CoopvestColors.warning),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: CoopvestColors.warning,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This is a mandatory consent required to access loans',
                        style: CoopvestTypography.bodySmall.copyWith(
                          color: CoopvestColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Consent Title
              Text(
                'Salary Deduction & Loan Recovery Authorization',
                style: CoopvestTypography.headlineMedium.copyWith(
                  color: CoopvestColors.darkGray,
                ),
              ),
              const SizedBox(height: 20),

              // Consent Content
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CoopvestColors.veryLightGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CoopvestColors.lightGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildConsentSection(
                      'Authorization for Salary Deduction and Loan Recovery',
                      'I, the undersigned member of Coopvest Africa Cooperative Society, hereby authorize Coopvest Africa, its agents, partners, and affiliated payroll administrators to deduct agreed loan repayments, contributions, or outstanding obligations directly from my salary or emoluments where applicable.',
                    ),
                    const SizedBox(height: 16),
                    _buildConsentSection(
                      'Scope of Authorization',
                      'I understand that this authorization applies strictly to obligations arising from:\n\n• Loans obtained through Coopvest Africa\n• Cooperative contributions where applicable\n• Recovery actions in the event of default, in line with Coopvest policies',
                    ),
                    const SizedBox(height: 16),
                    _buildConsentSection(
                      'Information Sharing',
                      'I consent to Coopvest Africa sharing my relevant employment and payroll information with my employer or authorized payroll processors solely for the purpose of facilitating deductions and ensuring compliance with cooperative agreements.',
                    ),
                    const SizedBox(height: 16),
                    _buildConsentSection(
                      'Limitations',
                      'I acknowledge that this authorization:\n\n• Does not grant Coopvest Africa unrestricted access to my salary\n• Is limited to agreed amounts and documented obligations\n• Can only be applied in accordance with Coopvest Africa\'s policies and applicable laws',
                    ),
                    const SizedBox(height: 16),
                    _buildConsentSection(
                      'Default Consequences',
                      'I further understand that failure to honor my loan obligations may trigger recovery actions involving my guarantors and/or salary deductions as permitted under this authorization.',
                    ),
                    const SizedBox(height: 16),
                    _buildConsentSection(
                      'Confirmation',
                      'By accepting this consent, I confirm that all information provided during registration is accurate and that I voluntarily agree to this authorization.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Acceptance Checkbox
              GestureDetector(
                onTap: () {
                  setState(() {
                    _agreeToConsent = !_agreeToConsent;
                  });
                },
                child: Row(
                  children: [
                    Checkbox(
                      value: _agreeToConsent,
                      onChanged: (value) {
                        setState(() {
                          _agreeToConsent = value ?? false;
                        });
                      },
                      activeColor: CoopvestColors.primary,
                    ),
                    Expanded(
                      child: Text(
                        'I have read and agree to the Salary Deduction Authorization',
                        style: CoopvestTypography.bodyMedium.copyWith(
                          color: CoopvestColors.darkGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Accept Button
              PrimaryButton(
                label: 'Accept & Continue',
                onPressed: _isSubmitting ? null : _submitConsent,
                isLoading: _isSubmitting,
                isEnabled: !_isSubmitting,
                width: double.infinity,
              ),
              const SizedBox(height: 16),

              // Decline Button
              SecondaryButton(
                label: 'Decline',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Decline Consent?'),
                      content: const Text(
                        'You cannot access loans without accepting this consent. You can still use other features of Coopvest.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.of(context).pushNamed('/home');
                          },
                          child: const Text('Proceed Without Loans'),
                        ),
                      ],
                    ),
                  );
                },
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: CoopvestTypography.labelLarge.copyWith(
            color: CoopvestColors.darkGray,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: CoopvestTypography.bodySmall.copyWith(
            color: CoopvestColors.mediumGray,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
