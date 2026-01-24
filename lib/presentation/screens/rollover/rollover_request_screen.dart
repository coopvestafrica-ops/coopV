import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme_config.dart';
import '../../../data/models/loan_models.dart';
import '../../../data/models/rollover_models.dart';
import '../../../data/api/rollover_api_service.dart';
import '../../providers/rollover_provider.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/cards.dart';
import '../../widgets/rollover/rollover_common_widgets.dart';

/// Rollover Request Screen
/// Allows member to request a rollover and select 3 guarantors
class RolloverRequestScreen extends ConsumerWidget {
  final Loan loan;

  const RolloverRequestScreen({super.key, required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolloverState = ref.watch(rolloverProvider);
    final rolloverNotifier = ref.read(rolloverProvider.notifier);

    // Calculate outstanding balance (mock calculation for demo)
    final outstandingBalance = loan.amount * 0.35; // 65% repaid
    final newTenureOptions = [4, 6, 8, 12];

    return Scaffold(
      backgroundColor: CoopvestColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Request Rollover'),
        backgroundColor: CoopvestColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rollover Summary
            _buildRolloverSummary(outstandingBalance, loan),
            const SizedBox(height: 24),

            // New Tenure Selection
            _buildTenureSelection(newTenureOptions, rolloverState.newTenure, (value) {
              // Handle tenure selection (would use StateProvider in real app)
            }),
            const SizedBox(height: 24),

            // Guarantor Selection
            _buildGuarantorSection(context, ref, rolloverState),
            const SizedBox(height: 24),

            // Important Notes
            _buildImportantNotes(),
            const SizedBox(height: 24),

            // Submit Button
            _buildSubmitButton(context, ref, rolloverNotifier),
          ],
        ),
      ),
    );
  }

  Widget _buildRolloverSummary(double outstandingBalance, Loan loan) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: CoopvestColors.info),
              SizedBox(width: 8),
              Text(
                'Rollover Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Original Loan Amount', loan.amount),
          _buildSummaryRow('Outstanding Balance', outstandingBalance),
          _buildSummaryRow('Current Interest Rate', '${loan.interestRate}%'),
          _buildSummaryRow('Original Tenure', '${loan.tenure} months'),
          const Divider(height: 16),
          const Text(
            'Note: The new loan will have the same interest rate but a new repayment tenor.',
            style: TextStyle(
              fontSize: 12,
              color: CoopvestColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, dynamic value) {
    final formattedValue = value is double
        ? value.toString()
        : value.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: CoopvestColors.textSecondary),
          ),
          Text(
            formattedValue,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenureSelection(
    List<int> options,
    int? selectedTenure,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select New Tenor',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose how long you need to repay the outstanding balance',
          style: TextStyle(fontSize: 13, color: CoopvestColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((tenure) {
            final isSelected = selectedTenure == tenure;
            return ChoiceChip(
              label: Text('$tenure months'),
              selected: isSelected,
              onSelected: (selected) => onChanged(tenure),
              selectedColor: CoopvestColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : CoopvestColors.textPrimary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGuarantorSection(
    BuildContext context,
    WidgetRef ref,
    RolloverState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Select 3 Guarantors',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${state.selectedGuarantors.length}/3',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: state.selectedGuarantors.length >= 3
                    ? CoopvestColors.success
                    : CoopvestColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'All 3 guarantors must provide fresh consent for this rollover.',
          style: TextStyle(fontSize: 12, color: CoopvestColors.textSecondary),
        ),
        const SizedBox(height: 16),

        // Selected Guarantors
        if (state.selectedGuarantors.isNotEmpty)
          ...state.selectedGuarantors.map((guarantor) {
            return GuarantorSelectionCard(
              guarantor: guarantor,
              onRemove: () => ref.read(rolloverProvider.notifier).removeGuarantor(guarantor.id),
            );
          }).toList(),

        // Add Guarantor Button
        const SizedBox(height: 12),
        SecondaryButton(
          label: '+ Add Guarantor',
          onPressed: () => _showAddGuarantorDialog(context, ref),
        ),

        // Validation Message
        if (state.selectedGuarantors.length < 3)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CoopvestColors.warning.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning, color: CoopvestColors.warning, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You need to select 3 guarantors to submit your rollover request.',
                      style: TextStyle(fontSize: 12, color: CoopvestColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showAddGuarantorDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const AddGuarantorDialog(),
    );
  }

  Widget _buildImportantNotes() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CoopvestColors.info.withAlpha((255 * 0.1).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CoopvestColors.info.withAlpha((255 * 0.3).toInt())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Important Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CoopvestColors.info,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '• This is NOT a loan increase - only the outstanding balance continues\n'
            '• All 3 guarantors must give FRESH consent\n'
            '• Your original loan will be closed and a new loan created\n'
            '• Admin approval is required after guarantor consent\n'
            '• No interest escalation - same rate applies',
            style: TextStyle(fontSize: 12, color: CoopvestColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(
    BuildContext context,
    WidgetRef ref,
    RolloverNotifier notifier,
  ) {
    final state = ref.watch(rolloverProvider);
    final isLoading = state.isLoading;
    final canSubmit = state.selectedGuarantors.length >= 3;
    return PrimaryButton(
      label: 'Submit Rollover Request',
      isLoading: isLoading,
      onPressed: () => _submitRollover(context, ref, notifier),
      isEnabled: canSubmit,
    );
  }

  Future<void> _submitRollover(
    BuildContext context,
    WidgetRef ref,
    RolloverNotifier notifier,
  ) async {
    final state = ref.read(rolloverProvider);

    final guarantors = state.selectedGuarantors.map((g) {
      return GuarantorInfo(
        guarantorId: g.id,
        guarantorName: g.name,
        guarantorPhone: g.phone,
      );
    }).toList();

    // Mock tenure selection
    final newTenure = 6;

    final success = await notifier.createRolloverRequest(
      loanId: loan.id,
      newTenure: newTenure,
      guarantors: guarantors,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rollover request submitted successfully!'),
          backgroundColor: CoopvestColors.success,
        ),
      );

      // Navigate to status screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RolloverStatusScreen(rolloverId: state.currentRollover?.id ?? ''),
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Failed to submit rollover request'),
          backgroundColor: CoopvestColors.error,
        ),
      );
    }
  }
}

/// Add Guarantor Dialog
class AddGuarantorDialog extends ConsumerWidget {
  const AddGuarantorDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    return AlertDialog(
      title: const Text('Add Guarantor'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Guarantor Name',
                hintText: 'Enter full name',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+234XXXXXXXXXX',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Phone is required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              ref.read(rolloverProvider.notifier).addGuarantor(
                GuarantorSelection(
                  id: 'GUAR-${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  phone: phoneController.text,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// Rollover Status Screen
class RolloverStatusScreen extends ConsumerWidget {
  final String rolloverId;

  const RolloverStatusScreen({super.key, required this.rolloverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rolloverProvider);
    final rollover = state.currentRollover;

    return Scaffold(
      appBar: AppBar(title: const Text('Rollover Status')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (rollover != null) ...[
              RolloverSummaryCard(rollover: rollover),
              const SizedBox(height: 24),
              _buildGuarantorStatusSection(state),
              const SizedBox(height: 24),
              _buildActionButtons(context, ref),
            ] else if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              const Center(child: Text('No rollover details found')),
          ],
        ),
      ),
    );
  }

  Widget _buildGuarantorStatusSection(RolloverState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Guarantor Consent',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.acceptedGuarantorsCount}/3 guarantors have consented',
              style: const TextStyle(fontSize: 13, color: CoopvestColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...state.guarantors.map((g) => GuarantorCard(guarantor: g)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rolloverProvider);
    final rollover = state.currentRollover;

    if (rollover?.status == RolloverStatus.pending) {
      return SecondaryButton(
        label: 'Cancel Rollover Request',
        onPressed: () => _showCancelDialog(context, ref),
      );
    }

    return const SizedBox.shrink();
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Rollover?'),
        content: const Text(
          'Are you sure you want to cancel this rollover request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Request'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CoopvestColors.error),
            onPressed: () {
              ref.read(rolloverProvider.notifier).cancelRollover(
                rolloverId: ref.read(rolloverProvider).currentRollover?.id ?? '',
              );
              Navigator.pop(context);
            },
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }
}

/// Placeholder classes for guarantor selection (would be in a StateProvider)
class GuarantorSelection {
  final String id;
  final String name;
  final String phone;

  GuarantorSelection({
    required this.id,
    required this.name,
    required this.phone,
  });
}

/// State extension for guarantor selection
extension RolloverStateExtension on RolloverState {
  List<GuarantorSelection> get selectedGuarantors => const [];
  int get newTenure => 6;
  int get acceptedGuarantorsCount => guarantors
      .where((g) => g.status == GuarantorConsentStatus.accepted)
      .length;
}

/// Guarantor Selection Card
class GuarantorSelectionCard extends StatelessWidget {
  final GuarantorSelection guarantor;
  final VoidCallback onRemove;

  const GuarantorSelectionCard({
    super.key,
    required this.guarantor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: CoopvestColors.primary.withAlpha((255 * 0.1).toInt()),
              child: Text(
                guarantor.name[0].toUpperCase(),
                style: const TextStyle(
                  color: CoopvestColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guarantor.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    guarantor.phone,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CoopvestColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
