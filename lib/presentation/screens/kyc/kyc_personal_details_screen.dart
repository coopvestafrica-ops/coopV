import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme_config.dart';
import '../../../presentation/providers/kyc_provider.dart';
import '../../../presentation/widgets/common/buttons.dart';
import '../../../presentation/widgets/common/cards.dart';
import '../../../presentation/widgets/common/inputs.dart';

/// KYC Personal Details Screen
class KYCPersonalDetailsScreen extends ConsumerStatefulWidget {
  const KYCPersonalDetailsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<KYCPersonalDetailsScreen> createState() => _KYCPersonalDetailsScreenState();
}

class _KYCPersonalDetailsScreenState extends ConsumerState<KYCPersonalDetailsScreen> {
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  
  String? _selectedState;
  String? _selectedLGA;
  
  final List<Map<String, dynamic>> _states = [
    {'label': 'Abia', 'value': 'abia'},
    {'label': 'Adamawa', 'value': 'adamawa'},
    {'label': 'Akwa Ibom', 'value': 'akwa_ibom'},
    {'label': 'Anambra', 'value': 'anambra'},
    {'label': 'Bauchi', 'value': 'bauchi'},
    {'label': 'Bayelsa', 'value': 'bayelsa'},
    {'label': 'Benue', 'value': 'benue'},
    {'label': 'Borno', 'value': 'borno'},
    {'label': 'Cross River', 'value': 'cross_river'},
    {'label': 'Delta', 'value': 'delta'},
    {'label': 'Ebonyi', 'value': 'ebonyi'},
    {'label': 'Edo', 'value': 'edo'},
    {'label': 'Ekiti', 'value': 'ekiti'},
    {'label': 'Enugu', 'value': 'enugu'},
    {'label': 'Gombe', 'value': 'gombe'},
    {'label': 'Imo', 'value': 'imo'},
    {'label': 'Jigawa', 'value': 'jigawa'},
    {'label': 'Kaduna', 'value': 'kaduna'},
    {'label': 'Kano', 'value': 'kano'},
    {'label': 'Katsina', 'value': 'katsina'},
    {'label': 'Kebbi', 'value': 'kebbi'},
    {'label': 'Kogi', 'value': 'kogi'},
    {'label': 'Kwara', 'value': 'kwara'},
    {'label': 'Lagos', 'value': 'lagos'},
    {'label': 'Nasarawa', 'value': 'nasarawa'},
    {'label': 'Niger', 'value': 'niger'},
    {'label': 'Ogun', 'value': 'ogun'},
    {'label': 'Ondo', 'value': 'ondo'},
    {'label': 'Osun', 'value': 'osun'},
    {'label': 'Oyo', 'value': 'oyo'},
    {'label': 'Plateau', 'value': 'plateau'},
    {'label': 'Rivers', 'value': 'rivers'},
    {'label': 'Sokoto', 'value': 'sokoto'},
    {'label': 'Taraba', 'value': 'taraba'},
    {'label': 'Yobe', 'value': 'yobe'},
    {'label': 'Zamfara', 'value': 'zamfara'},
  ];

  final Map<String, List<Map<String, dynamic>>> _lgasByState = {
    'lagos': [
      {'label': 'Alimosho', 'value': 'alimosho'},
      {'label': 'Amuwo-Odofin', 'value': 'amuwo_odofin'},
      {'label': 'Apapa', 'value': 'apapa'},
      {'label': 'Badagry', 'value': 'badagry'},
      {'label': 'Epe', 'value': 'epe'},
      {'label': 'Eti-Osa', 'value': 'eti_osa'},
      {'label': 'Ibeju-Lekki', 'value': 'ibeju_lekki'},
      {'label': 'Ifako-Ijaye', 'value': 'ifako_ijaye'},
      {'label': 'Ikeja', 'value': 'ikeja'},
      {'label': 'Ikorodu', 'value': 'ikorodu'},
      {'label': 'Kosofe', 'value': 'kosofe'},
      {'label': 'Lagos Island', 'value': 'lagos_island'},
      {'label': 'Lagos Mainland', 'value': 'lagos_mainland'},
      {'label': 'Mushin', 'value': 'mushin'},
      {'label': 'Ojo', 'value': 'ojo'},
      {'label': 'Shomolu', 'value': 'shomolu'},
      {'label': 'Surulere', 'value': 'surulere'},
    ],
    // Add more states and LGAs as needed
  };

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _validateAndContinue() {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your residential address'),
          backgroundColor: CoopvestColors.error,
        ),
      );
      return;
    }

    if (_cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your city'),
          backgroundColor: CoopvestColors.error,
        ),
      );
      return;
    }

    if (_selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your state'),
          backgroundColor: CoopvestColors.error,
        ),
      );
      return;
    }

    if (_selectedLGA == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your local government area'),
          backgroundColor: CoopvestColors.error,
        ),
      );
      return;
    }

    // Update KYC state
    ref.read(kycProvider.notifier).updateAddress(
      residentialAddress: _addressController.text,
      city: _cityController.text,
      stateValue: _selectedState!,
      country: null,
    );

    // Navigate to next step (Employment)
    Navigator.of(context).pushNamed('/kyc-employment');
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
          'Personal Details',
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
                  _buildProgressStep(1, true),
                  _buildProgressLine(1),
                  _buildProgressStep(2, false),
                  _buildProgressLine(2),
                  _buildProgressStep(3, true),
                  _buildProgressLine(3),
                  _buildProgressStep(4, true),
                ],
              ),
              const SizedBox(height: 32),

              // Header
              Text(
                'Where Do You Live?',
                style: CoopvestTypography.headlineSmall.copyWith(
                  color: CoopvestColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your residential information for verification purposes',
                style: CoopvestTypography.bodyMedium.copyWith(
                  color: CoopvestColors.mediumGray,
                ),
              ),
              const SizedBox(height: 24),

              // Residential Address
              AppTextField(
                label: 'Residential Address *',
                hint: 'Enter your full address',
                controller: _addressController,
                keyboardType: TextInputType.streetAddress,
                textInputAction: TextInputAction.next,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),

              // City
              AppTextField(
                label: 'City *',
                hint: 'Enter your city',
                controller: _cityController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'City is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),

              // State Selection
              Text(
                'State *',
                style: CoopvestTypography.labelLarge.copyWith(
                  color: CoopvestColors.darkGray,
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: CoopvestColors.lightGray),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedState,
                  hint: const Text('Select your state'),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _states.map((state) {
                    return DropdownMenuItem<String>(
                      value: state['value'] as String?,
                      child: Text(
                        state['label'] as String,
                        style: CoopvestTypography.bodyMedium,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedState = value;
                      _selectedLGA = null;
                    });
                  },
                ),
              ),
              
              const SizedBox(height: 16),

              // LGA Selection
              if (_selectedState != null)
                Text(
                  'Local Government Area (LGA) *',
                  style: CoopvestTypography.labelLarge.copyWith(
                    color: CoopvestColors.darkGray,
                  ),
                ),
              const SizedBox(height: 12),
              
              if (_selectedState != null)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: CoopvestColors.lightGray),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedLGA,
                    hint: const Text('Select your LGA'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: (_lgasByState[_selectedState] ?? []).map((lga) {
                      return DropdownMenuItem<String>(
                        value: lga['value'] as String?,
                        child: Text(
                          lga['label'] as String,
                          style: CoopvestTypography.bodyMedium,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLGA = value;
                      });
                    },
                  ),
                ),
              
              if (_selectedState == null)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: CoopvestColors.veryLightGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CoopvestColors.lightGray),
                  ),
                  child: Center(
                    child: Text(
                      'Select your state first to see available LGAs',
                      style: CoopvestTypography.bodyMedium.copyWith(
                        color: CoopvestColors.mediumGray,
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),

              // Address Verification Card
              AppCard(
                backgroundColor: CoopvestColors.info.withAlpha((255 * 0.1).toInt()),
                border: Border.all(color: CoopvestColors.info.withAlpha((255 * 0.3).toInt())),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: CoopvestColors.info,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your address information is used for identity verification and delivery purposes only.',
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
