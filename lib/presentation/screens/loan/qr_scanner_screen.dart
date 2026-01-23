import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../config/theme_config.dart';
import '../../../presentation/widgets/common/cards.dart';
import 'guarantor_verification_screen.dart';

/// QR Scanner Screen - For guarantors to scan loan QR codes
class QRScannerScreen extends StatefulWidget {
  final String guarantorId;
  final String guarantorName;

  const QRScannerScreen({
    super.key,
    required this.guarantorId,
    required this.guarantorName,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _hasScanned = false;
  bool _isProcessing = false;
  String _errorMessage = '';
  String? _scannedLoanId;

  void _handleBarcode(BarcodeCapture barcodes) {
    if (_hasScanned || _isProcessing) return;

    final List<Barcode> rawBarcodes = barcodes.barcodes;
    
    for (final barcode in rawBarcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.startsWith('COOP-')) {
        setState(() {
          _scannedLoanId = barcode.rawValue;
          _hasScanned = true;
        });

        // Process the scanned loan ID
        _processScannedLoan(_scannedLoanId!);
        break;
      }
    }
  }

  Future<void> _processScannedLoan(String loanId) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    try {
      // In production, this would be an API call to validate the loan
      // For now, we simulate the validation
      await Future.delayed(const Duration(seconds: 1));

      // Extract user ID from loan ID (format: COOP-USERID-LOAN-TIMESTAMP)
      final parts = loanId.split('-');
      if (parts.length < 4) {
        setState(() {
          _errorMessage = 'Invalid QR code format';
          _isProcessing = false;
        });
        return;
      }
      
      // Mock loan details - in production, fetch from API
      final loanDetails = await _fetchLoanDetails(loanId);
      
      if (loanDetails != null) {
        // Navigate to guarantor verification screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => GuarantorVerificationScreen(
                loanId: loanId,
                borrowerName: loanDetails['borrowerName'],
                loanAmount: loanDetails['amount'],
                loanType: loanDetails['loanType'] ?? 'Quick Loan',
                loanTenor: loanDetails['duration'] ?? 12,
                guarantorId: widget.guarantorId,
                guarantorName: widget.guarantorName,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Loan not found. Please try again.';
          _isProcessing = false;
        });
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing QR code: $e';
        _isProcessing = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchLoanDetails(String loanId) async {
    // Mock API call - in production, this would call your backend
    // Simulating API response
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Parse loan ID to extract info
    final parts = loanId.split('-');
    if (parts.length < 4) return null;
    
    return {
      'borrowerName': 'Coopvest Member', // Would come from API
      'amount': 50000.0, // Would come from API
      'purpose': 'Business expansion', // Would come from API
      'monthlyRepayment': 12500.0, // Would come from API
      'duration': 4, // Would come from API
      'interestRate': 7.5, // Would come from API
    };
  }

  void _resetScanner() {
    setState(() {
      _hasScanned = false;
      _isProcessing = false;
      _errorMessage = '';
      _scannedLoanId = null;
    });
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _goBack,
        ),
        title: const Text(
          'Scan Loan QR Code',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Scanner Area
          Expanded(
            flex: 1,
            child: Stack(
              children: [
                MobileScanner(
                  onDetect: _handleBarcode,
                ),
                
                // Scanner Overlay
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Scan Area Border
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: CoopvestColors.primary,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Instructions
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha((255 * 0.7).toInt()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Position QR code within the frame',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Loading Overlay
                if (_isProcessing)
                  Container(
                    color: Colors.black.withAlpha((255 * 0.8).toInt()),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(
                            color: CoopvestColors.primary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Processing QR Code...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Error Display
                if (_errorMessage.isNotEmpty)
                  Positioned(
                    bottom: 100,
                    left: 24,
                    right: 24,
                    child: AppCard(
                      backgroundColor: CoopvestColors.error.withAlpha((255 * 0.9).toInt()),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: _resetScanner,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Bottom Info
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Info Card
                AppCard(
                  backgroundColor: CoopvestColors.primary.withAlpha((255 * 0.2).toInt()),
                  border: Border.all(color: CoopvestColors.primary),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.info, color: CoopvestColors.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Scan a loan QR code to confirm your guarantee',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'By scanning, you agree to be responsible for 1/3 of the loan amount if the borrower defaults.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Your Info
                Text(
                  'Scanning as: ${widget.guarantorName}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
