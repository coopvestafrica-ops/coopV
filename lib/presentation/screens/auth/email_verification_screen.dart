import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme_config.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/inputs.dart';

/// Email Verification Screen
/// Shown when user needs to verify their email address
class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String? email;
  
  const EmailVerificationScreen({
    Key? key,
    this.email,
  }) : super(key: key);

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  late TextEditingController _emailController;
  late TextEditingController _otpController;
  bool _isResending = false;
  bool _isVerifying = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  String? _errorMessage;
  String? _successMessage;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
    _otpController = TextEditingController();
    _checkVerificationStatus();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    setState(() {
      _cooldownSeconds = seconds;
      _isResending = false;
    });

    _cooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (mounted) {
          setState(() {
            if (_cooldownSeconds > 0) {
              _cooldownSeconds--;
            } else {
              timer.cancel();
            }
          });
        }
      },
    );
  }

  Future<void> _checkVerificationStatus() async {
    if (_emailController.text.isEmpty) return;

    try {
      final response = await ApiClient().getDio().get(
        '/api/v1/auth/check-email-verification',
        queryParameters: {'email': _emailController.text},
      );

      if (response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _isVerified = response.data['isVerified'] ?? false;
          });
        }
        
        if (_isVerified && mounted) {
          // Navigate to home if already verified
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      // Silently fail, user can try again
      debugPrint('Error checking verification status: $e');
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address';
      });
      return;
    }

    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await ApiClient().getDio().post(
        '/api/v1/auth/resend-verification-email',
        queryParameters: {'email': _emailController.text},
      );

      if (mounted) {
        final data = response.data;
        
        if (data['success'] == true) {
          setState(() {
            _successMessage = 'Verification email sent! Check your inbox.';
            _errorMessage = null;
          });
          
          // Start cooldown if provided
          if (data['cooldownSeconds'] != null) {
            _startCooldown(data['cooldownSeconds']);
          }
        } else {
          setState(() {
            _errorMessage = data['error'] ?? 'Failed to send verification email';
          });
          
          // Handle cooldown response
          if (data['remainingSeconds'] != null) {
            _startCooldown(data['remainingSeconds']);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send verification email. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address';
      });
      return;
    }

    if (_otpController.text.length < 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit code';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await ApiClient().getDio().post(
        '/api/v1/auth/verify-otp',
        data: {
          'email': _emailController.text,
          'otp': _otpController.text,
        },
      );

      if (mounted) {
        final data = response.data;
        
        if (data['success'] == true) {
          setState(() {
            _isVerified = true;
            _successMessage = 'Email verified successfully!';
            _errorMessage = null;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Email verified successfully!'),
              backgroundColor: CoopvestColors.success,
            ),
          );
          
          // Navigate to home after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          });
        } else {
          setState(() {
            _errorMessage = data['error'] ?? 'Invalid verification code';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Verification failed. Please check the code and try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _manuallyCheckVerification() async {
    await _checkVerificationStatus();

    if (mounted) {
      if (_isVerified && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email verified successfully!'),
            backgroundColor: CoopvestColors.success,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        setState(() {
          _errorMessage = 'Email not yet verified. Please check your inbox or enter the OTP.';
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Email Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: CoopvestColors.primaryLight.withAlpha((255 * 0.1).toInt()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isVerified ? Icons.check_circle : Icons.mail_outline,
                  size: 50,
                  color: _isVerified 
                      ? CoopvestColors.success 
                      : CoopvestColors.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                _isVerified ? 'Email Verified!' : 'Verify Your Email',
                style: CoopvestTypography.headlineMedium.copyWith(
                  color: CoopvestColors.darkGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                _isVerified
                    ? 'Your email has been verified. You can now access all features.'
                    : 'Please enter the 6-digit code sent to your email or click the link in the verification email.',
                style: CoopvestTypography.bodyMedium.copyWith(
                  color: CoopvestColors.mediumGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Email & OTP Inputs
              if (!_isVerified) ...[
                AppTextField(
                  label: 'Email Address',
                  hint: 'Enter your registered email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.mail_outline, color: CoopvestColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                
                AppTextField(
                  label: 'Verification Code (OTP)',
                  hint: 'Enter 6-digit code',
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  showCounter: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.lock_outline, color: CoopvestColors.primary),
                  ),
                ),
                const SizedBox(height: 24),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: CoopvestColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: CoopvestColors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: CoopvestTypography.bodySmall.copyWith(
                              color: CoopvestColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Success Message
                if (_successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: CoopvestColors.success.withAlpha((255 * 0.1).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: CoopvestColors.success,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: CoopvestTypography.bodySmall.copyWith(
                              color: CoopvestColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Verify Button
                PrimaryButton(
                  label: 'Verify Code',
                  onPressed: _verifyOTP,
                  isLoading: _isVerifying,
                  width: double.infinity,
                ),
                const SizedBox(height: 16),

                // Resend Button with Cooldown
                _isResending
                    ? const CircularProgressIndicator(
                        color: CoopvestColors.primary,
                      )
                    : _cooldownSeconds > 0
                        ? Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[300],
                                    foregroundColor: Colors.grey[600],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Resend in ${_cooldownSeconds}s',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _manuallyCheckVerification,
                                child: const Text(
                                  'I\'ve already verified - Check Status',
                                  style: TextStyle(
                                    color: CoopvestColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              SecondaryButton(
                                label: 'Resend Verification Email',
                                onPressed: _resendVerificationEmail,
                                width: double.infinity,
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _manuallyCheckVerification,
                                child: const Text(
                                  'I\'ve already verified - Check Status',
                                  style: TextStyle(
                                    color: CoopvestColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
              ],

              // Already Verified - Go Home Button
              if (_isVerified) ...[
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Go to Dashboard',
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                  width: double.infinity,
                ),
              ],

              const SizedBox(height: 32),

              // Help Text
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
                        const Icon(
                          Icons.lightbulb_outline,
                          color: CoopvestColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Need Help?',
                          style: CoopvestTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: CoopvestColors.darkGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Check your spam/junk folder\n'
                      '• Make sure you entered the correct email\n'
                      '• The verification code expires in 24 hours',
                      style: CoopvestTypography.bodySmall.copyWith(
                        color: CoopvestColors.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Email Verification Required Overlay
/// Shows a full-screen overlay when user tries to access protected features
class EmailVerificationRequiredOverlay extends StatelessWidget {
  final String email;
  
  const EmailVerificationRequiredOverlay({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: CoopvestColors.warningLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber,
                size: 40,
                color: CoopvestColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Email Verification Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CoopvestColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please verify your email ($email) to access this feature.',
              style: TextStyle(
                fontSize: 14,
                color: CoopvestColors.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EmailVerificationScreen(email: email),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CoopvestColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Verify Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Later',
                style: TextStyle(
                  color: CoopvestColors.mediumGray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
