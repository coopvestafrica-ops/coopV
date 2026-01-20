import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/theme_config.dart';
import '../../../core/network/api_client.dart';
import 'ticket_detail_screen.dart';

/// Ticket List Screen
/// Shows user's tickets with filtering and search
class TicketListScreen extends ConsumerStatefulWidget {
  const TicketListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends ConsumerState<TicketListScreen> {
  bool _isLoading = true;
  List<dynamic> _tickets = [];
  String? _errorMessage;
  String _selectedStatus = '';
  
  // Status filter options
  final List<Map<String, String>> _statusFilters = [
    {'value': '', 'label': 'All'},
    {'value': 'open', 'label': 'Open'},
    {'value': 'in_progress', 'label': 'In Progress'},
    {'value': 'awaiting_user', 'label': 'Awaiting Response'},
    {'value': 'resolved', 'label': 'Resolved'},
    {'value': 'closed', 'label': 'Closed'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final params = <String, dynamic>{};
      if (_selectedStatus.isNotEmpty) {
        params['status'] = _selectedStatus;
      }

      final response = await ApiClient().getDio().get(
        '/api/v1/tickets',
        queryParameters: params,
      );

      if (response.data['success'] == true) {
        setState(() {
          _tickets = response.data['tickets'] ?? [];
        });
      } else {
        setState(() {
          _errorMessage = response.data['error'] ?? 'Failed to load tickets';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load tickets. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'awaiting_user':
        return Colors.purple;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  String _getCategoryDisplayName(String category) {
    final names = {
      'loan_issue': 'Loan Issue',
      'guarantor_consent': 'Guarantor Consent',
      'referral_bonus': 'Referral/Bonus',
      'repayment_issue': 'Repayment',
      'account_kyc': 'Account/KYC',
      'technical_bug': 'Technical Bug',
      'other': 'Other',
    };
    return names[category] ?? category;
  }

  String _getPriorityIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return '🔴';
      case 'high':
        return '🟠';
      case 'medium':
        return '🟡';
      case 'low':
        return '🟢';
      default:
        return '🟡';
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
        title: const Text(
          'My Tickets',
          style: TextStyle(
            color: CoopvestColors.darkGray,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: CoopvestColors.primary),
            onPressed: () {
              Navigator.of(context).pushNamed('/create-ticket');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.map((filter) {
                  final isSelected = _selectedStatus == filter['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter['label']!),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = selected ? filter['value']! : '';
                        });
                        _loadTickets();
                      },
                      selectedColor: CoopvestColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : CoopvestColors.darkGray,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _tickets.isEmpty
                        ? _buildEmptyView()
                        : _buildTicketList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: CoopvestColors.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: CoopvestColors.error),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadTickets,
              style: ElevatedButton.styleFrom(
                backgroundColor: CoopvestColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: CoopvestColors.primaryLight.withAlpha((255 * 0.1).toInt()),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 40,
                color: CoopvestColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Tickets Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CoopvestColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a support ticket when you need help.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CoopvestColors.mediumGray,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/create-ticket');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CoopvestColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Create Ticket'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList() {
    return RefreshIndicator(
      onRefresh: _loadTickets,
      color: CoopvestColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tickets.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
          final createdAt = DateTime.parse(ticket['createdAt']);
          final formattedDate = DateFormat('MMM d, y').format(createdAt);

          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TicketDetailScreen(
                    ticketId: ticket['ticketId'],
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket['ticketId'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: CoopvestColors.mediumGray,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(ticket['status'] ?? '').withAlpha((255 * 0.1).toInt()),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatStatus(ticket['status'] ?? ''),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(ticket['status'] ?? ''),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    ticket['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CoopvestColors.darkGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Category and Priority
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getCategoryDisplayName(ticket['category'] ?? ''),
                          style: TextStyle(
                            fontSize: 12,
                            color: CoopvestColors.mediumGray,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_getPriorityIcon(ticket['priority'] ?? 'medium')} ${(ticket['priority'] ?? 'medium').toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: CoopvestColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Footer
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: CoopvestColors.mediumGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: CoopvestColors.mediumGray,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: CoopvestColors.mediumGray,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
