import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme_config.dart';
import '../../../core/utils/utils.dart';
import '../../../presentation/widgets/common/buttons.dart';
import '../../../presentation/widgets/common/cards.dart';
import '../../../presentation/widgets/common/inputs.dart';

/// Withdrawal Screen
class WithdrawalScreen extends ConsumerStatefulWidget {
  final String userId;

  const WithdrawalScreen({super.key, required this.userId});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  
  // Mock available balance - in production, get from wallet provider
  double _availableBalance = 120000.0;

  Future<void> _processWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Withdrawal failed: $e'),
          backgroundColor: CoopvestColors.error,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: CoopvestColors.success),
            SizedBox(width: 8),
            Text('Withdrawal Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your withdrawal of ₦${_amountController.text} has been processed.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CoopvestColors.warning.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Funds will be transferred to your bank account within 24 hours.',
                style: CoopvestTypography.bodySmall.copyWith(
                  color: CoopvestColors.warning,
                ),
                textAlign: TextAlign.center,
              ),
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

  void _goBack() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
          'Withdraw Funds',
          style: CoopvestTypography.headlineLarge.copyWith(
            color: CoopvestColors.darkGray,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Available Balance Card
                AppCard(
                  backgroundColor: CoopvestColors.info.withAlpha((255 * 0.1).toInt()),
                  border: Border.all(color: CoopvestColors.info.withAlpha((255 * 0.3).toInt())),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available for Withdrawal',
                            style: CoopvestTypography.bodySmall.copyWith(
                              color: CoopvestColors.mediumGray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₦${_availableBalance.toStringAsFixed(2)}',
                            style: CoopvestTypography.headlineSmall.copyWith(
                              color: CoopvestColors.info,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.account_balance_wallet, color: CoopvestColors.info, size: 32),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Amount Input
                AppTextField(
                  label: 'Amount',
                  hint: 'Enter withdrawal amount',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  prefixText: '₦ ',
                  onChanged: (value) {
                    setState(() {});
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value.replaceAll(',', ''));
                    if (amount == null || amount < 100) {
                      return 'Minimum withdrawal is ₦100';
                    }
                    if (amount > _availableBalance) {
                      return 'Insufficient balance';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Quick Amount Buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [5000, 10000, 25000, 50000, 100000].map((amount) {
                    final isSelected = _amountController.text.replaceAll(',', '') == amount.toString();
                    return GestureDetector(
                      onTap: () {
                        if (amount <= _availableBalance) {
                          _amountController.text = amount.toString();
                          setState(() {});
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: amount <= _availableBalance
                              ? (isSelected ? CoopvestColors.primary : CoopvestColors.veryLightGray)
                              : CoopvestColors.veryLightGray,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: amount <= _availableBalance
                                ? (isSelected ? CoopvestColors.primary : CoopvestColors.lightGray)
                                : CoopvestColors.lightGray,
                          ),
                        ),
                        child: Text(
                          '₦${amount.formatNumber()}',
                          style: TextStyle(
                            color: amount <= _availableBalance
                                ? (isSelected ? Colors.white : CoopvestColors.darkGray)
                                : CoopvestColors.mediumGray,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Bank Account Info
                AppCard(
                  backgroundColor: CoopvestColors.veryLightGray,
                  child: Row(
                    children: [
                      Icon(Icons.account_balance, color: CoopvestColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Withdrawal to:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Access Bank ****1234',
                              style: TextStyle(color: CoopvestColors.mediumGray),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Info Card
                AppCard(
                  backgroundColor: CoopvestColors.warning.withAlpha((255 * 0.1).toInt()),
                  border: Border.all(color: CoopvestColors.warning.withAlpha((255 * 0.3).toInt())),
                  child: Row(
                    children: const [
                      Icon(Icons.info, color: CoopvestColors.warning),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Withdrawals are processed within 24 hours. A ₦10 fee applies to withdrawals under ₦5,000.',
                          style: TextStyle(color: CoopvestColors.darkGray),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                _isProcessing
                    ? const Center(child: CircularProgressIndicator(color: CoopvestColors.primary))
                    : PrimaryButton(
                        label: 'Withdraw ₦${_amountController.text.isEmpty ? '0' : _amountController.text}',
                        onPressed: _processWithdrawal,
                        width: double.infinity,
                      ),

                const SizedBox(height: 16),
                SecondaryButton(
                  label: 'Go Back',
                  onPressed: _goBack,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
