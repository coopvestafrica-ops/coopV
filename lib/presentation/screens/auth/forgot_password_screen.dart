import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme_config.dart';
import '../../../core/utils/utils.dart';
import '../../../core/services/api_service.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/inputs.dart';

/// Forgot Password Screen with Real API Integration
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late TextEditingController _emailController;
  String? _emailError;
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    setState(() {
      _emailError = Validators.validateEmail(_emailController.text);
    });

    if (_emailError == null) {
      _sendResetLink();
    }
  }

  Future<void> _sendResetLink() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Call API to send password reset link
      final apiService = ApiService();
      final response = await apiService.post(
        '/auth/forgot-password',
        data: {
          'email': _emailController.text.trim(),
        },
      );

      if (response['success'] == true) {
        if (mounted) {
          setState(() {
            _emailSent = true;
            _isLoading = false;
          });
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to send reset link');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset link: ${e.toString()}'),
            backgroundColor: CoopvestColors.error,
          ),
        );
      }
    }
  }

  Future<void> _resendResetLink() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.post(
        '/auth/forgot-password',
        data: {
          'email': _emailController.text.trim(),
        },
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset link sent successfully'),
            backgroundColor: CoopvestColors.success,
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to resend reset link');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend: ${e.toString()}'),
          backgroundColor: CoopvestColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CoopvestColors.darkGray),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Forgot Password',
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
              if (!_emailSent) ...[
                // Header
                Text(
                  'Reset Your Password',
                  style: CoopvestTypography.headlineMedium.copyWith(
                    color: CoopvestColors.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your email address and we\'ll send you a link to reset your password',
                  style: CoopvestTypography.bodyMedium.copyWith(
                    color: CoopvestColors.mediumGray,
                  ),
                ),
                const SizedBox(height: 32),

                // Email Field
                AppTextField(
                  label: 'Email Address',
                  hint: 'Enter your registered email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  errorText: _emailError,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.mail_outline, color: CoopvestColors.primary),
                  ),
                  onChanged: (_) {
                    if (_emailError != null) {
                      setState(() {
                        _emailError = Validators.validateEmail(_emailController.text);
                      });
                    }
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                PrimaryButton(
                  label: 'Send Reset Link',
                  onPressed: _validateAndSubmit,
                  isLoading: _isLoading,
                  isEnabled: !_isLoading,
                  width: double.infinity,
                ),
                const SizedBox(height: 16),

                // Back to Login
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Back to Login',
                      style: CoopvestTypography.bodyMedium.copyWith(
                        color: CoopvestColors.primary,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Success State
                const SizedBox(height: 48),
                
                // Success Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: CoopvestColors.success.withAlpha((255 * 0.1).toInt()),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: CoopvestColors.success,
                  ),
                ),
                const SizedBox(height: 32),

                // Success Message
                Text(
                  'Reset Link Sent!',
                  style: CoopvestTypography.headlineMedium.copyWith(
                    color: CoopvestColors.darkGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'We\'ve sent a password reset link to ${_emailController.text}. Please check your email and follow the instructions.',
                  style: CoopvestTypography.bodyMedium.copyWith(
                    color: CoopvestColors.mediumGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Resend Link
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Didn\'t receive the email?',
                        style: CoopvestTypography.bodySmall.copyWith(
                          color: CoopvestColors.mediumGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _isLoading ? null : _resendResetLink,
                        child: Text(
                          'Resend Link',
                          style: CoopvestTypography.bodyMedium.copyWith(
                            color: CoopvestColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Back to Login Button
                SecondaryButton(
                  label: 'Back to Login',
                  onPressed: () => Navigator.of(context).pop(),
                  width: double.infinity,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
