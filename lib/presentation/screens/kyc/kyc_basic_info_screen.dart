import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme_config.dart';
import '../../../presentation/providers/kyc_provider.dart';
import '../../../presentation/widgets/common/buttons.dart';
import '../../../presentation/widgets/common/cards.dart';
import '../../../presentation/widgets/common/inputs.dart';

/// KYC Basic Info Screen
class KYCBasicInfoScreen extends ConsumerStatefulWidget {
  const KYCBasicInfoScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<KYCBasicInfoScreen> createState() => _KYCBasicInfoScreenState();
}

class _KYCBasicInfoScreenState extends ConsumerState<KYCBasicInfoScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  
  final List<Map<String, dynamic>> _genders = [
    {'label': 'Male', 'value': 'male'},
    {'label': 'Female', 'value': 'female'},
    {'label': 'Other', 'value': 'other'},
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    
    // Pre-fill if data exists
    final submission = ref.read(kycProvider).submission;
    if (submission != null) {
      // Note: KYCRSubmission doesn't have firstName/lastName/email/phone fields
      // These might be stored elsewhere or need to be added
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: CoopvestColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: CoopvestColors.darkGray,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && mounted) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobController.text = _formatDate(picked);
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _validateAndContinue() {
    if (_firstNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your first name'),
          backgroundColor: CoopvestColors.error,
        ),
      );
      return;
    }

    if (_lastNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your last name'),
          backgroundColor: CoopvestColors.error,
        ),
      );
      return;
    }

    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: CoopvestColors.error,
        ),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: CoopvestColors.error,
        ),
      );
      return;
    }

    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: CoopvestColors.error,
        ),
      );
      return;
    }

    if (_phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number'),
          backgroundColor: CoopvestColors.error,
        ),
      );
      return;
    }

    if (_selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: CoopvestColors.error,
        ),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your gender'),
          backgroundColor: CoopvestColors.error,
        ),
      );
      return;
    }

    // Calculate age to ensure user is 18+
    final age = DateTime.now().difference(_selectedDateOfBirth!).inDays ~/ 365;
    if (age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be at least 18 years old to use this app'),
          backgroundColor: CoopvestColors.error,
        ),
      );
      return;
    }

    // Navigate to next step
    Navigator.of(context).pushNamed('/kyc-personal-details');
  }

  void _goBack() {
    ref.read(kycProvider.notifier).previousStep();
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
          'Basic Information',
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
                  _buildProgressStep(1, false),
                  _buildProgressLine(1),
                  _buildProgressStep(2, true),
                  _buildProgressLine(2),
                  _buildProgressStep(3, true),
                  _buildProgressLine(3),
                  _buildProgressStep(4, true),
                ],
              ),
              const SizedBox(height: 32),

              // Header
              Text(
                'Let\'s Start with Your Details',
                style: CoopvestTypography.headlineSmall.copyWith(
                  color: CoopvestColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide your basic information to create your account',
                style: CoopvestTypography.bodyMedium.copyWith(
                  color: CoopvestColors.mediumGray,
                ),
              ),
              const SizedBox(height: 24),

              // First Name
              AppTextField(
                label: 'First Name *',
                hint: 'Enter your first name',
                controller: _firstNameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),

              // Last Name
              AppTextField(
                label: 'Last Name *',
                hint: 'Enter your last name',
                controller: _lastNameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),

              // Email
              AppTextField(
                label: 'Email Address *',
                hint: 'Enter your email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),

              // Phone
              AppTextField(
                label: 'Phone Number *',
                hint: 'Enter your phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                maxLength: 11,
                prefixText: '+234 ',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),

              // Date of Birth
              AppTextField(
                label: 'Date of Birth *',
                hint: 'Select your date of birth',
                controller: _dobController,
                readOnly: true,
                onTap: _selectDateOfBirth,
                suffixIcon: Icon(Icons.calendar_today),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Date of birth is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),

              // Gender Selection
              Text(
                'Gender *',
                style: CoopvestTypography.labelLarge.copyWith(
                  color: CoopvestColors.darkGray,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _genders.map((gender) {
                  final isSelected = _selectedGender == gender['value'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedGender = gender['value'] as String?;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CoopvestColors.primary
                            : CoopvestColors.veryLightGray,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? CoopvestColors.primary
                              : CoopvestColors.lightGray,
                        ),
                      ),
                      child: Text(
                        gender['label'] as String,
                        style: CoopvestTypography.bodyMedium.copyWith(
                          color: isSelected ? Colors.white : CoopvestColors.darkGray,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 12),

              // Age Notice
              AppCard(
                backgroundColor: CoopvestColors.info.withAlpha((255 * 0.1).toInt()),
                border: Border.all(color: CoopvestColors.info.withAlpha((255 * 0.3).toInt())),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: CoopvestColors.info,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You must be at least 18 years old to create an account',
                        style: CoopvestTypography.bodySmall.copyWith(
                          color: CoopvestColors.darkGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Continue Button
              PrimaryButton(
                label: 'Continue',
                onPressed: _validateAndContinue,
                width: double.infinity,
              ),
              
              const SizedBox(height: 16),

              // Back Button
              SecondaryButton(
                label: 'Go Back',
                onPressed: _goBack,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStep(int step, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? CoopvestColors.primary : CoopvestColors.lightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: isActive
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
                '$step',
                style: TextStyle(
                  color: isActive ? Colors.white : CoopvestColors.mediumGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildProgressLine(int step) {
    final isComplete = step < 4; // All steps except last are complete
    return Expanded(
      child: Container(
        height: 2,
        color: isComplete ? CoopvestColors.primary : CoopvestColors.lightGray,
      ),
    );
  }
}
