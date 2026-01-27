/**
 * Wallet Routes
 * 
 * Wallet and transaction related endpoints
 */

const express = require('express');
const router = express.Router();
const { Wallet } = require('../models');
const { authenticate } = require('../middleware/auth');
const logger = require('../utils/logger');

/**
 * GET /api/v1/wallet/balance
 * Get user's wallet balance and recent transactions
 * REQUIRES: Valid JWT token
 */
router.get('/balance', authenticate, async (req, res) => {
  try {
    const userId = req.user.userId;

    let wallet = await Wallet.findOne({ userId });
    
    // If wallet doesn't exist, create one (lazy initialization)
    if (!wallet) {
      wallet = new Wallet({
        userId,
        balance: 0,
        transactions: []
      });
      await wallet.save();
    }

    res.json({
      success: true,
      balance: wallet.balance,
      currency: wallet.currency,
      recentTransactions: wallet.transactions.slice(-5).reverse(),
      lastUpdated: wallet.lastUpdated
    });
  } catch (error) {
    logger.error('Error getting wallet balance:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * GET /api/v1/wallet/transactions
 * Get user's transaction history
 * REQUIRES: Valid JWT token
 */
router.get('/transactions', authenticate, async (req, res) => {
  try {
    const userId = req.user.userId;
    const wallet = await Wallet.findOne({ userId });

    if (!wallet) {
      return res.json({
        success: true,
        transactions: [],
        total: 0
      });
    }

    res.json({
      success: true,
      transactions: wallet.transactions.reverse(),
      total: wallet.transactions.length
    });
  } catch (error) {
    logger.error('Error getting transactions:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;
