import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme_config.dart';
import '../../../../data/models/rollover_models.dart';
import '../../providers/rollover_provider.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/cards.dart';
import '../../widgets/rollover/rollover_common_widgets.dart';

/// Guarantor Consent Screen
/// Shows rollover details and guarantor consent status for members
class GuarantorConsentScreen extends ConsumerWidget {
  final String rolloverId;

  const GuarantorConsentScreen({super.key, required this.rolloverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rolloverProvider);
    final rollover = state.currentRollover;
    final guarantors = state.guarantors;

    return Scaffold(
      backgroundColor: CoopvestColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Guarantor Consent'),
        backgroundColor: CoopvestColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(rolloverProvider.notifier).getRolloverGuarantors(
                      rolloverId: rolloverId,
                    ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(rolloverProvider.notifier).getRolloverGuarantors(
                rolloverId: rolloverId,
              );
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rollover Summary
              if (rollover != null) RolloverSummaryCard(rollover: rollover),
              const SizedBox(height: 24),

              // Consent Progress
              _buildConsentProgress(guarantors),
              const SizedBox(height: 24),

              // Guarantor List
              _buildGuarantorList(context, guarantors, ref),
              const SizedBox(height: 24),

              // Next Steps
              _buildNextSteps(guarantors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentProgress(List<RolloverGuarantor> guarantors) {
    final total = guarantors.length;
    final accepted = guarantors
        .where((g) => g.status == GuarantorConsentStatus.accepted)
        .length;
    final declined = guarantors
        .where((g) => g.status == GuarantorConsentStatus.declined)
        .length;
    final pending = total - accepted - declined;

    final progress = total > 0 ? (accepted / total).toDouble() : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Guarantor Consent Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$accepted / $total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: accepted == total ? CoopvestColors.success : CoopvestColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: CoopvestColors.lightGray,
              valueColor: AlwaysStoppedAnimation<Color>(
                declined > 0 ? CoopvestColors.error : CoopvestColors.success,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusIndicator(CoopvestColors.success, 'Accepted: $accepted'),
              const SizedBox(width: 16),
              _buildStatusIndicator(CoopvestColors.error, 'Declined: $declined'),
              const SizedBox(width: 16),
              _buildStatusIndicator(Colors.grey, 'Pending: $pending'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildGuarantorList(
    BuildContext context,
    List<RolloverGuarantor> guarantors,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Guarantors',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'All guarantors must provide fresh consent for this rollover.',
          style: TextStyle(fontSize: 12, color: CoopvestColors.textSecondary),
        ),
        const SizedBox(height: 12),
        ...guarantors.map((guarantor) {
          return GuarantorDetailCard(
            guarantor: guarantor,
            showActions: guarantor.status == GuarantorConsentStatus.declined,
            onReplace: () =>
                _showReplaceGuarantorDialog(context, ref, guarantor),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNextSteps(List<RolloverGuarantor> guarantors) {
    final accepted = guarantors
        .where((g) => g.status == GuarantorConsentStatus.accepted)
        .length;
    final declined = guarantors
        .where((g) => g.status == GuarantorConsentStatus.declined)
        .length;

    if (declined > 0) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.warning, color: CoopvestColors.warning),
                SizedBox(width: 8),
                Text(
                  'Action Required',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CoopvestColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$declined guarantor(s) have declined to support this rollover. '
              'You must replace them before the rollover can proceed.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Replace Declined Guarantors',
              onPressed: () {
                // Handle replace action
              },
            ),
          ],
        ),
      );
    }

    if (accepted == 3) {
      return AppCard(
        child: Column(
          children: [
            const Icon(
              Icons.check_circle,
              color: CoopvestColors.success,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'All Guarantors Have Consented',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your rollover request is now pending admin approval. '
              'You will be notified once the admin reviews your request.',
              style: TextStyle(fontSize: 13, color: CoopvestColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.hourglass_empty, color: CoopvestColors.info),
              SizedBox(width: 8),
              Text(
                'Awaiting Responses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${3 - accepted} guarantor(s) still need to respond. '
            'They will receive notification to consent to this rollover.',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showReplaceGuarantorDialog(
    BuildContext context,
    WidgetRef ref,
    RolloverGuarantor oldGuarantor,
  ) {
    showDialog(
      context: context,
      builder: (context) => ReplaceGuarantorDialog(
        oldGuarantor: oldGuarantor,
        onReplace: (newGuarantor) {
          ref.read(rolloverProvider.notifier).replaceGuarantor(
                rolloverId: rolloverId,
                oldGuarantorId: oldGuarantor.id,
                newGuarantorId: newGuarantor['id'] ?? '',
                newGuarantorName: newGuarantor['name'] ?? '',
                newGuarantorPhone: newGuarantor['phone'] ?? '',
              );
        },
      ),
    );
  }
}

/// Guarantor Detail Card with full information
class GuarantorDetailCard extends StatelessWidget {
  final RolloverGuarantor guarantor;
  final bool showActions;
  final VoidCallback? onReplace;

  const GuarantorDetailCard({
    super.key,
    required this.guarantor,
    this.showActions = false,
    this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getAvatarColor(),
                  child: Text(
                    guarantor.guarantorName[0].toUpperCase(),
                    style: TextStyle(
                      color: _getAvatarColor().computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
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
                        guarantor.guarantorName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        guarantor.guarantorPhone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CoopvestColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GuarantorStatusBadge(status: guarantor.status),
              ],
            ),
            if (guarantor.status == GuarantorConsentStatus.declined &&
                guarantor.declineReason != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CoopvestColors.error.withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: CoopvestColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reason: ${guarantor.declineReason}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CoopvestColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showActions) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  label: 'Replace This Guarantor',
                  onPressed: onReplace ?? () {},
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor() {
    switch (guarantor.status) {
      case GuarantorConsentStatus.accepted:
        return CoopvestColors.success.withAlpha((255 * 0.2).toInt());
      case GuarantorConsentStatus.declined:
        return CoopvestColors.error.withAlpha((255 * 0.2).toInt());
      case GuarantorConsentStatus.invited:
        return CoopvestColors.info.withAlpha((255 * 0.2).toInt());
      default:
        return CoopvestColors.lightGray;
    }
  }
}

/// Replace Guarantor Dialog
class ReplaceGuarantorDialog extends StatefulWidget {
  final RolloverGuarantor oldGuarantor;
  final Function(Map<String, String>) onReplace;

  const ReplaceGuarantorDialog({
    super.key,
    required this.oldGuarantor,
    required this.onReplace,
  });

  @override
  State<ReplaceGuarantorDialog> createState() => _ReplaceGuarantorDialogState();
}

class _ReplaceGuarantorDialogState extends State<ReplaceGuarantorDialog> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Replace Guarantor'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CoopvestColors.warning.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: CoopvestColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replacing: ${widget.oldGuarantor.guarantorName}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                label: Text('New Guarantor Name'),
                hintText: 'Enter full name',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(
                label: Text('New Guarantor Phone'),
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
              widget.onReplace({
                'id': 'NEW-${DateTime.now().millisecondsSinceEpoch}',
                'name': nameController.text,
                'phone': phoneController.text,
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Replace'),
        ),
      ],
    );
  }
}
