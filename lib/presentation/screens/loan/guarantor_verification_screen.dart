import 'package:flutter/material.dart';
import '../../../config/theme_config.dart';
import '../../../presentation/widgets/common/buttons.dart';
import '../../../presentation/widgets/common/cards.dart';

/// Guarantor Verification Screen - Complete 3-Guarantor Consent Flow
/// Flow: QR Scan → Review → Consent (No redundant login needed - user is already authenticated)
class GuarantorVerificationScreen extends StatefulWidget {
  final String loanId;
  final String borrowerName;
  final double loanAmount;
  final String loanType;
  final int loanTenor;
  final String guarantorId;
  final String guarantorName;
  final String? guarantorPhone;

  const GuarantorVerificationScreen({
    super.key,
    required this.loanId,
    required this.borrowerName,
    required this.loanAmount,
    required this.loanType,
    required this.loanTenor,
    required this.guarantorId,
    required this.guarantorName,
    this.guarantorPhone,
  });

  @override
  State<GuarantorVerificationScreen> createState() => _GuarantorVerificationScreenState();
}

class _GuarantorVerificationScreenState extends State<GuarantorVerificationScreen> {
  String _verificationStatus = 'review'; // Start directly at review - user is already authenticated
  bool _isProcessing = false;
  bool _agreedToTerms = false;
  
  // Calculate liability (1/3 of loan amount)
  double get _guarantorLiability => widget.loanAmount / 3;

  Future<void> _confirmConsent() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please read and accept the liability terms to proceed'),
          backgroundColor: CoopvestColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _verificationStatus = 'processing';
    });

    try {
      // Simulate API call to confirm guarantee
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _verificationStatus = 'confirmed';
        _isProcessing = false;
      });
      
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _verificationStatus = 'consent';
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to confirm guarantee: $e'),
          backgroundColor: CoopvestColors.error,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: CoopvestColors.success, size: 32),
            SizedBox(width: 12),
            Text('Guarantee Confirmed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your guarantee has been successfully recorded.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CoopvestColors.primary.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Your Liability Share',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₦${_guarantorLiability.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: CoopvestColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '(1/3 of ₦${widget.loanAmount.toStringAsFixed(2)})',
                    style: TextStyle(color: CoopvestColors.mediumGray),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You will be notified if the borrower defaults on this loan.',
              style: TextStyle(color: CoopvestColors.mediumGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _declineGuarantee() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Decline Guarantee'),
          ],
        ),
        content: const Text(
          'Are you sure you want to decline this guarantee request? The borrower will need to find another guarantor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Decline',
              style: TextStyle(color: CoopvestColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CoopvestColors.darkGray),
          onPressed: _goBack,
        ),
        title: Text(
          'Guarantee Consent',
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
              // Progress Stepper (Updated - 3 steps instead of 4)
              _buildProgressStepper(),
              const SizedBox(height: 24),

              // Show appropriate screen based on status
              if (_verificationStatus == 'review')
                _buildReviewScreen()
              else if (_verificationStatus == 'consent')
                _buildConsentScreen()
              else if (_verificationStatus == 'processing' || _verificationStatus == 'confirmed')
                _buildProcessingScreen(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStepper() {
    final steps = ['Review', 'Consent', 'Confirm'];
    int currentStep;
    if (_verificationStatus == 'review') {
      currentStep = 0;
    } else if (_verificationStatus == 'consent') {
      currentStep = 1;
    } else if (_verificationStatus == 'processing' || _verificationStatus == 'confirmed') {
      currentStep = 2;
    } else {
      currentStep = 0;
    }

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              color: index ~/ 2 < currentStep 
                  ? CoopvestColors.primary 
                  : CoopvestColors.lightGray,
            ),
          );
        }
        
        final stepIndex = index ~/ 2;
        final isActive = stepIndex <= currentStep;
        final isCompleted = stepIndex < currentStep;
        
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? CoopvestColors.primary : CoopvestColors.lightGray,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : CoopvestColors.mediumGray,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      }),
    );
  }

  Widget _buildReviewScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Loan Summary Card
        AppCard(
          backgroundColor: CoopvestColors.primary.withAlpha((255 * 0.05).toInt()),
          border: Border.all(color: CoopvestColors.primary.withAlpha((255 * 0.2).toInt())),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.description, color: CoopvestColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Loan Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('Borrower:', widget.borrowerName),
              _buildSummaryRow('Loan Type:', widget.loanType),
              _buildSummaryRow('Amount:', '₦${widget.loanAmount.toStringAsFixed(2)}'),
              _buildSummaryRow('Tenor:', '${widget.loanTenor} months'),
              _buildSummaryRow('Monthly Repayment:', '₦${(widget.loanAmount * 1.075 / widget.loanTenor).toStringAsFixed(2)}'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Guarantor Count Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withAlpha((255 * 0.3).toInt())),
          ),
          child: Row(
            children: [
              const Icon(Icons.info, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '3 Guarantors Required',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Exactly 3 guarantors must consent to this loan. You are 1 of them.',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        PrimaryButton(
          label: 'Review Liability Terms',
          onPressed: () {
            setState(() {
              _verificationStatus = 'consent';
            });
          },
          width: double.infinity,
        ),

        const SizedBox(height: 16),
        SecondaryButton(
          label: 'Decline',
          onPressed: _declineGuarantee,
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _buildConsentScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Liability Statement Card
        AppCard(
          backgroundColor: CoopvestColors.warning.withAlpha((255 * 0.1).toInt()),
          border: Border.all(color: CoopvestColors.warning.withAlpha((255 * 0.3).toInt())),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel, color: CoopvestColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    'Legal Liability Statement',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: CoopvestColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'By clicking "I Consent" below, I legally agree that:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildLiabilityPoint('If the borrower defaults on this loan, the outstanding balance will be divided equally among the 3 guarantors'),
              _buildLiabilityPoint('I am liable for exactly 1/3 of the total loan amount:'),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: CoopvestColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₦${_guarantorLiability.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildLiabilityPoint('Coopvest may recover funds from my wallet balance, savings, or salary deductions'),
              _buildLiabilityPoint('This consent is legally binding and cannot be revoked once all 3 guarantors have consented'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Consent Checkbox
        GestureDetector(
          onTap: () {
            setState(() {
              _agreedToTerms = !_agreedToTerms;
            });
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _agreedToTerms ? CoopvestColors.primary : Colors.transparent,
                  border: Border.all(
                    color: _agreedToTerms ? CoopvestColors.primary : CoopvestColors.mediumGray,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _agreedToTerms
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: CoopvestColors.darkGray, fontSize: 14),
                    children: [
                      const TextSpan(
                        text: 'I have read and understood the liability statement above. I ',
                      ),
                      TextSpan(
                        text: 'LEGALLY CONSENT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: CoopvestColors.primary,
                        ),
                      ),
                      const TextSpan(
                        text: ' to guarantee this loan and accept full liability for 1/3 of the outstanding balance if the borrower defaults.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        _isProcessing
            ? const Center(child: CircularProgressIndicator(color: CoopvestColors.primary))
            : Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _agreedToTerms ? _confirmConsent : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CoopvestColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'I CONSENT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _declineGuarantee,
                    child: const Text(
                      'Decline This Request',
                      style: TextStyle(color: CoopvestColors.error),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildProcessingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_verificationStatus == 'confirmed')
            const Icon(Icons.check_circle, color: CoopvestColors.success, size: 80)
          else
            const CircularProgressIndicator(color: CoopvestColors.primary, strokeWidth: 80),
          const SizedBox(height: 24),
          Text(
            _verificationStatus == 'confirmed'
                ? 'Guarantee Confirmed!'
                : 'Processing Your Consent...',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _verificationStatus == 'confirmed'
                ? 'Your consent has been recorded successfully.'
                : 'Please wait while we process your consent...',
            style: TextStyle(color: CoopvestColors.mediumGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: CoopvestColors.mediumGray)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLiabilityPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: CoopvestColors.warning)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
