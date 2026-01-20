/**
 * Auth Routes
 * 
 * Authentication endpoints with secure JWT handling
 */

const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const { User } = require('../models');
const logger = require('../utils/logger');

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  next();
};

// Validate JWT secret on module load
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  logger.error('FATAL: JWT_SECRET environment variable is not set!');
  logger.error('Please set JWT_SECRET in your .env file');
}

// Generate JWT token
const generateToken = (userId) => {
  return jwt.sign(
    { userId },
    JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};

/**
 * POST /api/v1/auth/register
 * Register a new user with optional referral code
 */
router.post('/register', [
  body('email').isEmail().withMessage('Valid email is required'),
  body('phone').notEmpty().withMessage('Phone number is required'),
  body('phone').isMobilePhone().withMessage('Valid phone number is required'),
  body('name').notEmpty().withMessage('Name is required'),
  body('name').isLength({ min: 2, max: 100 }).withMessage('Name must be 2-100 characters'),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('password').matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/).withMessage('Password must contain uppercase, lowercase, and number'),
  body('referralCode').optional().isString().isLength({ min: 8, max: 12 })
], validate, async (req, res) => {
  try {
    const { email, phone, name, password, referralCode } = req.body;

    const existingUser = await User.findOne({ 
      $or: [{ email: email.toLowerCase() }, { phone }] 
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        error: 'User with this email or phone already exists'
      });
    }

    const userId = `USR-${Date.now().toString(36).toUpperCase()}`;

    const user = new User({
      userId,
      email: email.toLowerCase(),
      phone,
      name,
      password,
      referral: {
        myReferralCode: User.generateReferralCode(userId)
      }
    });

    await user.save();

    if (referralCode) {
      try {
        const { referralService } = require('../services/referralService');
        await referralService.registerReferral(referralCode, userId, name);
      } catch (refError) {
        logger.warn('Referral registration failed:', refError.message);
      }
    }

    // Send email verification
    const frontendUrl = req.body.frontendUrl || process.env.FRONTEND_URL || 'http://localhost:3000';
    try {
      const { emailVerificationService } = require('../services/emailVerificationService');
      await emailVerificationService.sendVerificationEmail(user, frontendUrl);
    } catch (emailError) {
      logger.warn('Failed to send verification email:', emailError.message);
    }

    const token = generateToken(userId);

    res.status(201).json({
      success: true,
      user: {
        userId: user.userId,
        email: user.email,
        name: user.name,
        referralCode: user.referral.myReferralCode,
        emailVerified: user.emailVerification.isVerified
      },
      token,
      message: 'User registered successfully. Please verify your email.'
    });
  } catch (error) {
    logger.error('Registration error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * POST /api/v1/auth/login
 * Login user
 */
router.post('/login', [
  body('email').isEmail(),
  body('password').notEmpty()
], validate, async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email: email.toLowerCase() }).select('+password');
    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }

    if (!user.isActive) {
      return res.status(403).json({
        success: false,
        error: 'Account is deactivated'
      });
    }

    const token = generateToken(user.userId);

    res.json({
      success: true,
      user: {
        userId: user.userId,
        email: user.email,
        name: user.name,
        referralCode: user.referral.myReferralCode,
        kycVerified: user.kyc.verified,
        emailVerified: user.emailVerification.isVerified
      },
      token
    });
  } catch (error) {
    logger.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * POST /api/v1/auth/logout
 * Logout user (invalidate token)
 */
router.post('/logout', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      
      try {
        const { tokenBlacklist } = require('../services/tokenBlacklistService');
        const decoded = jwt.verify(token, JWT_SECRET);
        await tokenBlacklist.add(token, decoded.exp);
        logger.info(`Token blacklisted for user: ${decoded.userId}`);
      } catch (blacklistError) {
        logger.debug('Token blacklist error (non-critical):', blacklistError.message);
      }
    }

    res.json({
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    logger.error('Logout error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * POST /api/v1/auth/refresh
 * Refresh access token
 */
router.post('/refresh', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: 'Token required'
      });
    }

    const token = authHeader.split(' ')[1];

    try {
      const { tokenBlacklist } = require('../services/tokenBlacklistService');
      const isBlacklisted = await tokenBlacklist.isBlacklisted(token);
      if (isBlacklisted) {
        return res.status(401).json({
          success: false,
          error: 'Token has been revoked'
        });
      }
    } catch (e) {
      // Redis might not be available
    }

    const decoded = jwt.verify(token, JWT_SECRET);
    const newToken = generateToken(decoded.userId);

    res.json({
      success: true,
      token: newToken
    });
  } catch (error) {
    logger.error('Token refresh error:', error);
    res.status(401).json({
      success: false,
      error: 'Invalid or expired token'
    });
  }
});

/**
 * GET /api/v1/auth/me
 * Get current user profile
 */
router.get('/me', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, JWT_SECRET);
    
    const user = await User.findOne({ userId: decoded.userId });
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    if (!user.isActive) {
      return res.status(403).json({
        success: false,
        error: 'Account is deactivated'
      });
    }

    res.json({
      success: true,
      user: {
        userId: user.userId,
        email: user.email,
        name: user.name,
        phone: user.phone,
        referralCode: user.referral.myReferralCode,
        kycVerified: user.kyc.verified,
        emailVerified: user.emailVerification.isVerified,
        savings: user.savings,
        createdAt: user.createdAt
      }
    });
  } catch (error) {
    logger.error('Get profile error:', error);
    res.status(401).json({
      success: false,
      error: 'Invalid token'
    });
  }
});

module.exports = router;
