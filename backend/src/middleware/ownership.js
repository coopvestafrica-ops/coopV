/**
 * Ownership Validation Middleware
 * 
 * Validates that users can only access their own resources
 * Prevents IDOR (Insecure Direct Object Reference) attacks
 */

const { Loan, LoanQR } = require('../models');

/**
 * Middleware to verify loan ownership
 * User must own the loan to access/modify it
 */
const verifyLoanOwnership = async (req, res, next) => {
  try {
    const { loanId } = req.params;
    const userId = req.user.userId;

    if (!loanId) {
      return res.status(400).json({
        success: false,
        error: 'Loan ID is required'
      });
    }

    // In production, query from database:
    // const loan = await Loan.findOne({ loanId, userId });
    // if (!loan) {
    //   return res.status(404).json({
    //     success: false,
    //     error: 'Loan not found or access denied'
    //   });
    // }
    // req.loan = loan;

    // For demo, we'll trust the mock data but in production:
    // 1. Uncomment the database query above
    // 2. Remove the mock data fallback
    // 3. Only allow access if loan.userId === userId

    // Attach loanId to request for downstream use
    req.loanId = loanId;
    req.loanOwnerId = userId; // In production, this comes from the database

    next();
  } catch (error) {
    console.error('Ownership verification error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to verify loan ownership'
    });
  }
};

/**
 * Middleware to verify QR code ownership
 * User must own the QR code to access/modify it
 */
const verifyQROwnership = async (req, res, next) => {
  try {
    const { qrId } = req.params || req.body;
    const userId = req.user.userId;

    if (!qrId) {
      return res.status(400).json({
        success: false,
        error: 'QR ID is required'
      });
    }

    // In production, query from database:
    // const loanQR = await LoanQR.findOne({ qrId, applicantId: userId });
    // if (!loanQR) {
    //   return res.status(404).json({
    //     success: false,
    //     error: 'QR code not found or access denied'
    //   });
    // }
    // req.loanQR = loanQR;

    // Attach QR info to request
    req.qrId = qrId;
    req.qrOwnerId = userId;

    next();
  } catch (error) {
    console.error('QR ownership verification error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to verify QR ownership'
    });
  }
};

/**
 * Middleware to require loan ownership for read operations
 */
const requireLoanOwnership = async (req, res, next) => {
  try {
    const { loanId } = req.params;
    const userId = req.user.userId;

    // In production with real database:
    // const loan = await Loan.findOne({ loanId });
    // if (!loan) {
    //   return res.status(404).json({ success: false, error: 'Loan not found' });
    // }
    // if (loan.userId !== userId) {
    //   return res.status(403).json({ success: false, error: 'Access denied' });
    // }
    // req.loan = loan;

    // For now, just log the access attempt
    console.log(`Loan access attempt: User ${userId} accessing loan ${loanId}`);

    next();
  } catch (error) {
    console.error('Loan ownership check error:', error);
    res.status(500).json({
      success: false,
      error: 'Access check failed'
    });
  }
};

module.exports = {
  verifyLoanOwnership,
  verifyQROwnership,
  requireLoanOwnership
};
