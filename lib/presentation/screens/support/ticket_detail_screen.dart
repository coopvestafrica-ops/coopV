import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../config/theme_config.dart';
import '../../../core/network/api_client.dart';

/// Ticket Detail Screen
/// Shows ticket details and conversation thread
class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  
  const TicketDetailScreen({
    Key? key,
    required this.ticketId,
  }) : super(key: key);

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  bool _isLoading = true;
  bool _isReplying = false;
  Map<String, dynamic>? _ticket;
  List<dynamic> _messages = [];
  String? _errorMessage;
  final TextEditingController _replyController = TextEditingController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadTicketDetails();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadTicketDetails(),
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTicketDetails() async {
    try {
      final response = await ApiClient().getDio().get(
        '/api/v1/tickets/${widget.ticketId}',
      );

      if (response.data['success'] == true) {
        setState(() {
          _ticket = response.data['ticket'];
          _messages = response.data['messages'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.data['error'] ?? 'Failed to load ticket';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load ticket. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() {
      _isReplying = true;
    });

    try {
      final response = await ApiClient().getDio().post(
        '/api/v1/tickets/${widget.ticketId}/messages',
        data: {
          'content': _replyController.text.trim(),
        },
      );

      if (response.data['success'] == true) {
        _replyController.clear();
        _loadTicketDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['error'] ?? 'Failed to send reply'),
            backgroundColor: CoopvestColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send reply'),
          backgroundColor: CoopvestColors.error,
        ),
      );
    } finally {
      setState(() {
        _isReplying = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open': return Colors.blue;
      case 'in_progress': return Colors.orange;
      case 'awaiting_user': return Colors.purple;
      case 'resolved': return Colors.green;
      case 'closed': return Colors.grey;
      default: return Colors.grey;
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
      case 'urgent': return '🔴';
      case 'high': return '🟠';
      case 'medium': return '🟡';
      case 'low': return '🟢';
      default: return '🟡';
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ticket Details',
              style: TextStyle(
                color: CoopvestColors.darkGray,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            if (_ticket != null)
              Text(
                _ticket!['ticketId'] ?? '',
                style: TextStyle(
                  color: CoopvestColors.mediumGray,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: CoopvestColors.primary),
            onPressed: _loadTicketDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : Column(
                  children: [
                    // Ticket Info Header
                    _buildTicketHeader(),
                    
                    // Divider
                    Divider(color: Colors.grey[200]),
                    
                    // Messages
                    Expanded(
                      child: _messages.isEmpty
                          ? _buildEmptyMessagesView()
                          : _buildMessagesList(),
                    ),
                    
                    // Reply Input
                    _buildReplyInput(),
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
              onPressed: _loadTicketDetails,
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

  Widget _buildTicketHeader() {
    if (_ticket == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and Priority
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusColor(_ticket!['status'] ?? '').withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatStatus(_ticket!['status'] ?? ''),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(_ticket!['status'] ?? ''),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_getPriorityIcon(_ticket!['priority'] ?? 'medium')} ${(_ticket!['priority'] ?? 'medium').toUpperCase()}',
                style: TextStyle(
                  fontSize: 12,
                  color: CoopvestColors.mediumGray,
                ),
              ),
              const Spacer(),
              Text(
                _getCategoryDisplayName(_ticket!['category'] ?? ''),
                style: TextStyle(
                  fontSize: 12,
                  color: CoopvestColors.mediumGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Title
          Text(
            _ticket!['title'] ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CoopvestColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          
          // Related References
          if (_ticket!['relatedReference'] != null)
            Row(
              children: [
                if (_ticket!['relatedReference']['loanId'] != null)
                  _buildReferenceChip(
                    'Loan: ${_ticket!['relatedReference']['loanId']}',
                  ),
                if (_ticket!['relatedReference']['referralId'] != null)
                  _buildReferenceChip(
                    'Referral: ${_ticket!['relatedReference']['referralId']}',
                  ),
              ],
            ),
          
          const SizedBox(height: 8),
          
          // Timestamps
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: CoopvestColors.mediumGray),
              const SizedBox(width: 4),
              Text(
                'Created: ${DateFormat('MMM d, y h:mm a').format(DateTime.parse(_ticket!['createdAt']))}',
                style: TextStyle(fontSize: 12, color: CoopvestColors.mediumGray),
              ),
              const SizedBox(width: 16),
              Text(
                'Updated: ${DateFormat('MMM d, y h:mm a').format(DateTime.parse(_ticket!['updatedAt']))}',
                style: TextStyle(fontSize: 12, color: CoopvestColors.mediumGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: CoopvestColors.mediumGray),
      ),
    );
  }

  Widget _buildEmptyMessagesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 60,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              color: CoopvestColors.mediumGray,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isUser = message['senderType'] == 'user';
        final createdAt = DateTime.parse(message['createdAt']);
        final formattedTime = DateFormat('MMM d, h:mm a').format(createdAt);

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser 
                  ? CoopvestTheme.lightTheme.primaryColor
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: isUser ? null : Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender info
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isUser)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: CoopvestColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      isUser ? 'You' : 'Support Team',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isUser ? Colors.white : CoopvestColors.darkGray,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 10,
                        color: isUser ? Colors.white70 : CoopvestColors.mediumGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Message content
                Text(
                  message['content'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: isUser ? Colors.white : CoopvestColors.darkGray,
                  ),
                ),
                
                // Attachments if any
                if (message['attachments'] != null && 
                    (message['attachments'] as List).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: (message['attachments'] as List).map((attachment) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isUser 
                              ? Colors.white.withAlpha((255 * 0.2).toInt())
                              : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isUser 
                                ? Colors.white.withAlpha((255 * 0.3).toInt())
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 14,
                              color: isUser ? Colors.white : CoopvestColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'File',
                              style: TextStyle(
                                fontSize: 12,
                                color: isUser ? Colors.white : CoopvestColors.darkGray,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).toInt()),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Type your reply...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: CoopvestColors.lightGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: CoopvestColors.lightGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: CoopvestTheme.lightTheme.primaryColor,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: CoopvestColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isReplying ? null : _sendReply,
              icon: _isReplying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
