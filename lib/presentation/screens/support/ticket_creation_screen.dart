import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../config/theme_config.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/inputs.dart';

/// Ticket Creation Screen
/// Form to create a new support ticket
class TicketCreationScreen extends ConsumerStatefulWidget {
  final String? preselectedCategory;
  final String? preselectedCategoryName;
  
  const TicketCreationScreen({
    Key? key,
    this.preselectedCategory,
    this.preselectedCategoryName,
  }) : super(key: key);

  @override
  ConsumerState<TicketCreationScreen> createState() => _TicketCreationScreenState();
}

class _TicketCreationScreenState extends ConsumerState<TicketCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _loanIdController;
  late TextEditingController _referralIdController;
  
  // State
  String _selectedCategory = '';
  String _selectedPriority = 'medium';
  List<File> _attachments = [];
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _duplicateWarning;

  // Categories
  final List<Map<String, String>> _categories = [
    {'value': 'loan_issue', 'title': 'Loan Issue'},
    {'value': 'guarantor_consent', 'title': 'Guarantor Consent Issue'},
    {'value': 'referral_bonus', 'title': 'Referral / Bonus Issue'},
    {'value': 'repayment_issue', 'title': 'Repayment Issue'},
    {'value': 'account_kyc', 'title': 'Account / KYC Issue'},
    {'value': 'technical_bug', 'title': 'Technical Bug'},
    {'value': 'other', 'title': 'Other'},
  ];

  // Priorities
  final List<Map<String, String>> _priorities = [
    {'value': 'low', 'title': 'Low', 'icon': '🟢'},
    {'value': 'medium', 'title': 'Medium', 'icon': '🟡'},
    {'value': 'high', 'title': 'High', 'icon': '🟠'},
    {'value': 'urgent', 'title': 'Urgent', 'icon': '🔴'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _loanIdController = TextEditingController();
    _referralIdController = TextEditingController();
    
    // Set preselected category if provided
    if (widget.preselectedCategory != null) {
      _selectedCategory = widget.preselectedCategory!;
    }
    
    // Check rate limit on init
    _checkRateLimit();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _loanIdController.dispose();
    _referralIdController.dispose();
    super.dispose();
  }

  Future<void> _checkRateLimit() async {
    try {
      final response = await ApiClient().getDio().get(
        '/api/v1/tickets/rate-limit/status',
      );
      
      if (response.data['success'] == true) {
        if (response.data['canCreate'] != true) {
          setState(() {
            _errorMessage = 'You have reached your daily ticket limit. Please try again tomorrow.';
          });
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultipleMedia(
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      setState(() {
        _attachments.addAll(
          pickedFiles.map((file) => File(file.path)).toList()
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick images')),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory.isEmpty) {
      setState(() {
        _errorMessage = 'Please select a category';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Build request data
      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'loanId': _loanIdController.text.trim().isEmpty ? null : _loanIdController.text.trim(),
        'referralId': _referralIdController.text.trim().isEmpty ? null : _referralIdController.text.trim(),
      };

      final response = await ApiClient().getDio().post(
        '/api/v1/tickets',
        data: data,
      );

      if (response.data['success'] == true) {
        // Check for duplicates
        if (response.data['ticket']?['isDuplicated'] == true) {
          setState(() {
            _duplicateWarning = 'This may be similar to an existing ticket you have.';
          });
        }

        // Show success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _duplicateWarning != null 
                  ? 'Ticket created (possible duplicate detected)'
                  : 'Ticket created successfully!'
              ),
              backgroundColor: CoopvestTheme.lightTheme.primaryColor,
            ),
          );
          
          // Navigate to ticket list
          Navigator.of(context).pushReplacementNamed('/tickets');
        }
      } else {
        setState(() {
          _errorMessage = response.data['error'] ?? 'Failed to create ticket';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create ticket. Please try again.';
      });
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
        leading: IconButton(
          icon: const Icon(Icons.close, color: CoopvestColors.darkGray),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Ticket',
          style: TextStyle(
            color: CoopvestColors.darkGray,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
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
                            style: const TextStyle(
                              color: CoopvestColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_errorMessage != null) const SizedBox(height: 16),

                // Duplicate Warning
                if (_duplicateWarning != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _duplicateWarning!,
                            style: TextStyle(
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_duplicateWarning != null) const SizedBox(height: 16),

                // Category
                const Text(
                  'Category *',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: CoopvestColors.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Category Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category['value'];
                    return ChoiceChip(
                      label: Text(category['title']!),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category['value']!;
                          _errorMessage = null;
                        });
                      },
                      selectedColor: CoopvestColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : CoopvestColors.darkGray,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Priority
                const Text(
                  'Priority',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: CoopvestColors.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: _priorities.map((priority) {
                    final isSelected = _selectedPriority == priority['value'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPriority = priority['value']!;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? CoopvestTheme.lightTheme.primaryColor.withAlpha((255 * 0.1).toInt())
                                : Colors.grey[100],
                            border: Border.all(
                              color: isSelected 
                                  ? CoopvestTheme.lightTheme.primaryColor
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                priority['icon']!,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                priority['title']!,
                                style: TextStyle(
                                  color: isSelected 
                                      ? CoopvestTheme.lightTheme.primaryColor
                                      : CoopvestColors.mediumGray,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Title
                AppTextField(
                  label: 'Title *',
                  hint: 'Brief summary of your issue',
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    if (value.trim().length < 10) {
                      return 'Title must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Description
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: CoopvestColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 6,
                      maxLength: 5000,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        if (value.trim().length < 30) {
                          return 'Please provide more details (at least 30 characters)';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Describe your issue in detail...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: CoopvestColors.lightGray),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: CoopvestColors.lightGray),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: CoopvestTheme.lightTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Related References (Optional)
                const Text(
                  'Related Reference (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: CoopvestColors.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                
                AppTextField(
                  label: 'Loan ID',
                  hint: 'Related loan ID',
                  controller: _loanIdController,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                
                AppTextField(
                  label: 'Referral ID',
                  hint: 'Related referral ID',
                  controller: _referralIdController,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),

                // Attachments
                const Text(
                  'Attachments (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: CoopvestColors.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Attachment List
                if (_attachments.isNotEmpty)
                  Column(
                    children: _attachments.asMap().entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.image, color: CoopvestColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _attachments[entry.key].path.split('/').last,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => _removeAttachment(entry.key),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                
                // Add Attachment Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.attach_file, color: CoopvestColors.primary),
                    label: const Text(
                      'Add Images',
                      style: TextStyle(color: CoopvestColors.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: CoopvestColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Supported: JPG, PNG, GIF, PDF (Max 5MB per file)',
                  style: TextStyle(
                    fontSize: 12,
                    color: CoopvestColors.mediumGray,
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                PrimaryButton(
                  label: 'Submit Ticket',
                  onPressed: _submitTicket,
                  isLoading: _isSubmitting,
                  isEnabled: !_isSubmitting && _errorMessage == null,
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
