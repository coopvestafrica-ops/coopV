import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme_config.dart';
import '../../../core/services/api_service.dart';
import '../../widgets/common/buttons.dart';

/// Registration Step 2 - Email Verification with OTP - Real API Integration
class RegisterStep2Screen extends ConsumerStatefulWidget {
  final String email;
  final Map<String, String> registrationData;

  const RegisterStep2Screen({
    Key? key,
    required this.email,
    required this.registrationData,
  }) : super(key: key);

  @override
  ConsumerState<RegisterStep2Screen> createState() => _RegisterStep2ScreenState();
}

class _RegisterStep2ScreenState extends ConsumerState<RegisterStep2Screen> {
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _otpFocusNodes;
  int _remainingSeconds = 60;
  bool _canResend = false;
  bool _isVerifying = false;
  bool _isResending = false;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (_) => FocusNode());
    _startTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds == 0) {
            _canResend = true;
          } else {
            _startTimer();
          }
        });
      }
    });
  }

  Future<void> _resendOTP() async {
    setState(() {
      _remainingSeconds = 60;
      _canResend = false;
      _isResending = true;
      for (var controller in _otpControllers) {
        controller.clear();
      }
    });
    _startTimer();

    try {
      // Call API to resend OTP to email
      final response = await _apiService.post(
        '/auth/resend-otp',
        data: {
          'email': widget.email,
        },
      );

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to resend OTP');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent to your email successfully'),
            backgroundColor: CoopvestColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend OTP: ${e.toString()}'),
            backgroundColor: CoopvestColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _onOTPFieldChanged(String value, int index) {
    if (value.length == 1) {
      if (index < 5) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  String _getOTP() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOTP() async {
    final otp = _getOTP();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits'),
          backgroundColor: CoopvestColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // Call API to verify OTP using email
      final response = await _apiService.post(
        '/auth/verify-otp',
        data: {
          'email': widget.email,
          'otp': otp,
        },
      );

      if (response['success'] == true) {
        if (mounted) {
          Navigator.of(context).pushNamed(
            '/register-step3',
            arguments: widget.registrationData,
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Verification failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${e.toString()}'),
            backgroundColor: CoopvestColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
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
          'Verify Email',
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
              // Progress Indicator
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: CoopvestColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.check, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: CoopvestColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: CoopvestColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        '2',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Header
              Text(
                'Verify Your Email Address',
                style: CoopvestTypography.headlineMedium.copyWith(
                  color: CoopvestColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to ${widget.email}',
                style: CoopvestTypography.bodyMedium.copyWith(
                  color: CoopvestColors.mediumGray,
                ),
              ),
              const SizedBox(height: 32),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => Flexible(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index == 5 ? 0 : 8,
                      ),
                      height: 60,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        onChanged: (value) => _onOTPFieldChanged(value, index),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: CoopvestColors.veryLightGray,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: CoopvestColors.lightGray,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: CoopvestColors.lightGray,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: CoopvestColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        style: CoopvestTypography.displaySmall.copyWith(
                          color: CoopvestColors.darkGray,
                          fontSize: 20, // Slightly smaller font to fit better
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Resend OTP
              Center(
                child: Column(
                  children: [
                    if (!_canResend)
                      Text(
                        'Resend code in ${_remainingSeconds}s',
                        style: CoopvestTypography.bodySmall.copyWith(
                          color: CoopvestColors.mediumGray,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _isResending ? null : _resendOTP,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Text(
                            _isResending ? 'Sending...' : 'Resend Code',
                            style: CoopvestTypography.bodyMedium.copyWith(
                              color: CoopvestColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Verify Button
              PrimaryButton(
                label: 'Verify',
                onPressed: _verifyOTP,
                isLoading: _isVerifying,
                isEnabled: !_isVerifying,
                width: double.infinity,
              ),
              const SizedBox(height: 16),

              // Change Email
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Change Email Address',
                    style: CoopvestTypography.bodyMedium.copyWith(
                      color: CoopvestColors.primary,
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
}
