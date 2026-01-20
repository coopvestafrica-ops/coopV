/**
 * Referral Service
 * 
 * Core business logic for referral operations
 */

const { v4: uuidv4 } = require('uuid');
const { Referral, User, AuditLog } = require('../models');
const logger = require('../utils/logger');

class ReferralService {
  constructor() {
    // Configuration from environment
    this.lockInDays = parseInt(process.env.REFERRAL_LOCK_IN_DAYS) || 30;
    this.minSavingsMonths = parseInt(process.env.REFERRAL_MIN_SAVINGS_MONTHS) || 3;
    this.minSavingsAmount = parseFloat(process.env.REFERRAL_MIN_SAVINGS_AMOUNT) || 5000;
    
    // Tier configuration
    this.tierThresholds = {
      2: 2.0,  // 2 referrals = 2%
      4: 3.0,  // 4 referrals = 3%
      6: 4.0   // 6 referrals = 4% (max)
    };
    this.maxBonusPercent = 4.0;
  }

  /**
   * Calculate tier bonus based on confirmed referral count
   */
  calculateTierBonus(confirmedReferralCount) {
    if (confirmedReferralCount >= 6) return this.maxBonusPercent;
    if (confirmedReferralCount >= 4) return 3.0;
    if (confirmedReferralCount >= 2) return 2.0;
    return 0;
  }

  /**
   * Get tier name from bonus percentage
   */
  getTierName(bonusPercent) {
    if (bonusPercent >= 4) return 'Gold';
    if (bonusPercent >= 3) return 'Silver';
    if (bonusPercent >= 2) return 'Bronze';
    return 'None';
  }

  /**
   * Register a new referral
   */
  async registerReferral(referralCode, referredUserId, referredUserName) {
    try {
      // Validate input
      if (!referralCode || !referredUserId || !referredUserName) {
        throw new Error('Missing required parameters');
      }

      // Find referrer
      const referrer = await User.findOne({ 'referral.myReferralCode': referralCode });
      if (!referrer) {
        throw new Error('Invalid referral code');
      }

      // Check for self-referral
      if (referrer.userId === referredUserId) {
        await this.logAuditEvent('SELF_REFERRAL_DETECTED', null, referredUserId, null, 
          'Self-referral attempt detected and blocked');
        throw new Error('Self-referrals are not allowed');
      }

      // Check for existing referral relationship
      const existingReferral = await Referral.findOne({
        referredId: referredUserId,
        referrerId: referrer.userId
      });

      if (existingReferral) {
        throw new Error('Referral already exists for this user');
      }

      // Check for duplicate device/account
      const abuseCheck = await this.checkForAbuse(referrer.userId, referredUserId);
      if (abuseCheck.isDuplicate) {
        await this.logAuditEvent('DUPLICATE_DETECTED', null, referredUserId, referrer.userId,
          `Duplicate detected: ${abuseCheck.reason}`);
        throw new Error('Referral not allowed: duplicate account detected');
      }

      // Create new referral
      const referral = new Referral({
        referralCode,
        referrerId: referrer.userId,
        referrerName: referrer.name,
        referredId: referredUserId,
        referredName: referredUserName
      });

      await referral.save();

      // Update referred user's record
      await User.findOneAndUpdate(
        { userId: referredUserId },
        {
          'referral.referredBy': referrer.userId,
          'referral.referredByCode': referralCode
        }
      );

      // Log the action
      await this.logAuditEvent('REFERRAL_REGISTERED', referral.referralId, referredUserId, null,
        `New referral registered: ${referredUserName} using code ${referralCode}`);

      logger.info(`New referral registered: ${referral.referralId}`);

      return {
        success: true,
        referral,
        message: 'Referral registered successfully'
      };
    } catch (error) {
      logger.error('Error registering referral:', error.message);
      throw error;
    }
  }

  /**
   * Check referral status and qualification
   */
  async checkReferralStatus(referralId) {
    try {
      const referral = await Referral.findOne({ referralId });
      
      if (!referral) {
        throw new Error('Referral not found');
      }

      // Check if already confirmed
      if (referral.confirmed) {
        return {
          qualified: true,
          confirmed: true,
          kycVerified: referral.kycVerified,
          savingsCriteriaMet: referral.savingsCriteriaMet,
          isFlagged: referral.isFlagged,
          flagReason: referral.flaggedReason,
          message: 'Referral already confirmed',
          lockInEndDate: referral.lockInEndDate,
          tierBonusPercent: referral.tierBonusPercent
        };
      }

      // Check qualification criteria
      const kycVerified = referral.kycVerified;
      const savingsCriteriaMet = referral.savingsCriteriaMet;
      const qualified = kycVerified && savingsCriteriaMet && !referral.isFlagged;

      return {
        qualified,
        confirmed: false,
        kycVerified,
        savingsCriteriaMet,
        consecutiveSavingsMonths: referral.consecutiveSavingsMonths,
        requiredSavingsMonths: this.minSavingsMonths,
        isFlagged: referral.isFlagged,
        flagReason: referral.flaggedReason,
        message: qualified 
          ? 'Referral meets all qualification criteria' 
          : 'Referral does not meet qualification criteria yet',
        tierBonusPercent: referral.tierBonusPercent
      };
    } catch (error) {
      logger.error('Error checking referral status:', error.message);
      throw error;
    }
  }

  /**
   * Confirm a referral (when qualification criteria are met)
   */
  async confirmReferral(referralId, referredUserId) {
    try {
      const referral = await Referral.findOne({ referralId });
      
      if (!referral) {
        throw new Error('Referral not found');
      }

      if (referral.confirmed) {
        throw new Error('Referral is already confirmed');
      }

      // Validate qualification
      if (!referral.kycVerified || !referral.savingsCriteriaMet) {
        throw new Error('Referral does not meet qualification criteria');
      }

      if (referral.isFlagged) {
        throw new Error('Referral is flagged and cannot be confirmed');
      }

      // Confirm the referral with lock-in period
      await referral.confirmReferral(this.lockInDays);

      // Update referrer's referral count and tier
      await this.updateReferrerTier(referral.referrerId);

      // Log the action
      await this.logAuditEvent('REFERRAL_CONFIRMED', referral.referralId, referredUserId, null,
        `Referral confirmed. Lock-in ends: ${referral.lockInEndDate.toISOString()}`);

      logger.info(`Referral confirmed: ${referralId}`);

      return {
        success: true,
        referral,
        message: 'Referral confirmed successfully. Bonus will be available after lock-in period.',
        lockInEndDate: referral.lockInEndDate
      };
    } catch (error) {
      logger.error('Error confirming referral:', error.message);
      throw error;
    }
  }

  /**
   * Update a referred member's qualification status
   */
  async updateReferralQualification(referredUserId) {
    try {
      // Get user's verification status
      const user = await User.findOne({ userId: referredUserId });
      if (!user) {
        throw new Error('User not found');
      }

      // Find active referral for this user
      const referral = await Referral.findOne({ 
        referredId: referredUserId,
        confirmed: false 
      });

      if (!referral) {
        return { message: 'No active referral found for this user' };
      }

      // Update qualification fields
      const previousState = {
        kycVerified: referral.kycVerified,
        savingsCriteriaMet: referral.savingsCriteriaMet
      };

      referral.kycVerified = user.kyc.verified;
      referral.kycVerifiedDate = user.kyc.verifiedAt;
      referral.savingsCriteriaMet = user.meetsSavingsCriteria(this.minSavingsMonths, this.minSavingsAmount);
      referral.consecutiveSavingsMonths = user.savings.consecutiveMonths;
      referral.totalSavingsAmount = user.savings.totalSaved;
      
      if (user.savings.firstSavingsDate && !referral.minimumSavingsDate) {
        referral.minimumSavingsDate = new Date(user.savings.firstSavingsDate);
        referral.minimumSavingsDate.setMonth(referral.minimumSavingsDate.getMonth() + this.minSavingsMonths);
      }

      await referral.save();

      // Log if qualification status changed
      if (previousState.kycVerified !== referral.kycVerified || 
          previousState.savingsCriteriaMet !== referral.savingsCriteriaMet) {
        await this.logAuditEvent('REFERRAL_CONFIRMED', referral.referralId, referredUserId, null,
          `Qualification updated: KYC=${referral.kycVerified}, Savings=${referral.savingsCriteriaMet}`);
      }

      return {
        success: true,
        referral,
        message: 'Referral qualification updated'
      };
    } catch (error) {
      logger.error('Error updating referral qualification:', error.message);
      throw error;
    }
  }

  /**
   * Get user's referral summary
   */
  async getReferralSummary(userId) {
    try {
      const user = await User.findOne({ userId });
      if (!user) {
        throw new Error('User not found');
      }

      const referralCode = user.referral.myReferralCode;
      
      // Get detailed summary from Referral model
      const summary = await Referral.getUserReferralSummary(userId, referralCode);

      // Calculate progress to next tier
      const confirmedCount = summary.confirmedReferrals;
      let referralsToNext = 0;
      
      if (confirmedCount < 2) referralsToNext = 2 - confirmedCount;
      else if (confirmedCount < 4) referralsToNext = 4 - confirmedCount;
      else if (confirmedCount < 6) referralsToNext = 6 - confirmedCount;
      
      summary.referralsToNextTier = referralsToNext;
      summary.isMaxTier = confirmedCount >= 6;

      return {
        success: true,
        summary
      };
    } catch (error) {
      logger.error('Error getting referral summary:', error.message);
      throw error;
    }
  }

  /**
   * Apply referral bonus to a loan application
   */
  async applyBonusToLoan(userId, loanId, loanType) {
    try {
      // Get user's current tier bonus
      const summary = await this.getReferralSummary(userId);
      const bonusPercent = summary.summary.currentTierBonus;
      const isBonusAvailable = summary.summary.isBonusAvailable;

      if (!isBonusAvailable || bonusPercent <= 0) {
        return {
          success: false,
          error: 'No referral bonus available',
          bonusApplied: false
        };
      }

      // Check minimum interest floor for loan type
      const minimumFloor = this.getMinimumInterestFloor(loanType);
      const baseRate = this.getBaseInterestRate(loanType);
      
      if (baseRate - bonusPercent < minimumFloor) {
        return {
          success: false,
          error: `Cannot apply ${bonusPercent}% bonus. Minimum interest floor for ${loanType} is ${minimumFloor}%`,
          bonusApplied: false,
          minimumFloor
        };
      }

      // Mark bonus as consumed
      const referral = await Referral.findOne({
        referrerId: userId,
        confirmed: true,
        isFlagged: false,
        bonusConsumed: false,
        lockInEndDate: { $lte: new Date() }
      });

      if (referral) {
        await referral.applyBonusToLoan(loanId);
        
        // Update all referrals for this user to current tier
        await Referral.updateUserTierBonuses(userId);

        // Log the action
        await this.logAuditEvent('BONUS_CONSUMED', referral.referralId, userId, null, loanId,
          `Bonus of ${bonusPercent}% applied to loan ${loanId}`);

        logger.info(`Bonus applied to loan ${loanId}: ${bonusPercent}%`);
      }

      return {
        success: true,
        bonusApplied: true,
        bonusPercent,
        effectiveInterestRate: baseRate - bonusPercent,
        loanId,
        message: `Referral bonus of ${bonusPercent}% applied successfully`
      };
    } catch (error) {
      logger.error('Error applying bonus to loan:', error.message);
      throw error;
    }
  }

  /**
   * Calculate loan interest with referral bonus
   */
  calculateInterestWithBonus(loanType, loanAmount, tenureMonths, bonusPercent) {
    const baseRate = this.getBaseInterestRate(loanType);
    const minimumFloor = this.getMinimumInterestFloor(loanType);
    
    // Calculate effective rate (cannot go below minimum floor)
    const effectiveRate = bonusPercent > 0 
      ? Math.max(baseRate - bonusPercent, minimumFloor)
      : baseRate;

    // Calculate EMI using standard formula
    const monthlyRate = effectiveRate / 100 / 12;
    const emi = loanAmount * monthlyRate * Math.pow(1 + monthlyRate, tenureMonths) / 
                (Math.pow(1 + monthlyRate, tenureMonths) - 1);

    const monthlyRateBefore = baseRate / 100 / 12;
    const emiBeforeBonus = loanAmount * monthlyRateBefore * Math.pow(1 + monthlyRateBefore, tenureMonths) / 
                           (Math.pow(1 + monthlyRateBefore, tenureMonths) - 1);

    const totalSavingsFromBonus = (emiBeforeBonus - emi) * tenureMonths;

    return {
      loanType,
      baseInterestRate: baseRate,
      referralBonusPercent: bonusPercent,
      effectiveInterestRate: effectiveRate,
      loanAmount,
      tenureMonths,
      monthlyRepaymentBeforeBonus: emiBeforeBonus,
      monthlyRepaymentAfterBonus: emi,
      totalSavingsFromBonus,
      minimumInterestFloor: minimumFloor,
      bonusApplied: bonusPercent > 0
    };
  }

  /**
   * Get share link for referral
   */
  async getShareLink(userId) {
    try {
      const user = await User.findOne({ userId });
      if (!user) {
        throw new Error('User not found');
      }

      const referralCode = user.referral.myReferralCode;
      const baseUrl = process.env.API_BASE_URL || 'https://coopvest.app';
      const shareLink = `${baseUrl}/register?ref=${referralCode}`;

      return {
        success: true,
        referralCode,
        shareLink,
        qrCodeUrl: `${baseUrl}/api/v1/referrals/qr/${referralCode}`
      };
    } catch (error) {
      logger.error('Error getting share link:', error.message);
      throw error;
    }
  }

  /**
   * Update referrer's tier after new confirmation
   */
  async updateReferrerTier(referrerId) {
    try {
      // Count confirmed referrals
      const confirmedCount = await Referral.countDocuments({
        referrerId,
        confirmed: true,
        isFlagged: false
      });

      // Calculate new tier bonus
      const tierBonus = this.calculateTierBonus(confirmedCount);

      // Update referrer's profile
      await User.findOneAndUpdate(
        { userId: referrerId },
        {
          'referral.confirmedReferralCount': confirmedCount,
          'referral.currentTierBonus': tierBonus
        }
      );

      // Update all unconsumed referrals for this user
      await Referral.updateUserTierBonuses(referrerId);

      // Log tier update
      await this.logAuditEvent('TIER_UPDATED', null, referrerId, null,
        `User reached ${confirmedCount} confirmed referrals. Tier bonus: ${tierBonus}%`);

      return tierBonus;
    } catch (error) {
      logger.error('Error updating referrer tier:', error.message);
      throw error;
    }
  }

  /**
   * Check for abuse (self-referral, duplicate accounts)
   */
  async checkForAbuse(referrerId, referredUserId) {
    // Check self-referral
    if (referrerId === referredUserId) {
      return { isDuplicate: true, reason: 'Self-referral' };
    }

    // Check if referred user was already referred by someone else
    const existingReferral = await Referral.findOne({ referredId: referredUserId });
    if (existingReferral) {
      return { isDuplicate: true, reason: 'Already referred by another user' };
    }

    // Check device fingerprinting (if implemented)
    // This would require additional device tracking logic

    return { isDuplicate: false };
  }

  /**
   * Flag a referral for review
   */
  async flagReferral(referralId, reason, adminId) {
    try {
      const referral = await Referral.findOne({ referralId });
      if (!referral) {
        throw new Error('Referral not found');
      }

      await referral.flagReferral(reason, adminId);

      await this.logAuditEvent('REFERRAL_FLAGGED', referralId, referral.referredId, adminId,
        `Referral flagged: ${reason}`);

      return {
        success: true,
        referral,
        message: 'Referral flagged successfully'
      };
    } catch (error) {
      logger.error('Error flagging referral:', error.message);
      throw error;
    }
  }

  /**
   * Unflag a referral
   */
  async unflagReferral(referralId, adminId) {
    try {
      const referral = await Referral.findOne({ referralId });
      if (!referral) {
        throw new Error('Referral not found');
      }

      await referral.unflagReferral();

      await this.logAuditEvent('REFERRAL_UNFLAGGED', referralId, referral.referredId, adminId,
        'Referral unflagged by admin');

      return {
        success: true,
        referral,
        message: 'Referral unflagged successfully'
      };
    } catch (error) {
      logger.error('Error unflagging referral:', error.message);
      throw error;
    }
  }

  /**
   * Revoke a referral bonus
   */
  async revokeBonus(referralId, reason, adminId) {
    try {
      const referral = await Referral.findOne({ referralId });
      if (!referral) {
        throw new Error('Referral not found');
      }

      const previousBonus = referral.tierBonusPercent;
      
      referral.tierBonusPercent = 0;
      referral.bonusConsumed = false;
      referral.bonusUsedLoanId = null;
      referral.bonusUsedDate = null;
      
      await referral.save();

      // Re-calculate referrer's tier
      await this.updateReferrerTier(referral.referrerId);

      await this.logAuditEvent('REFERRAL_REVOKED', referralId, referral.referredId, adminId,
        `Bonus revoked: ${previousBonus}% -> 0%. Reason: ${reason}`);

      return {
        success: true,
        referral,
        message: 'Bonus revoked successfully'
      };
    } catch (error) {
      logger.error('Error revoking bonus:', error.message);
      throw error;
    }
  }

  /**
   * Get base interest rate for loan type
   */
  getBaseInterestRate(loanType) {
    const rates = {
      'Quick Loan': 7.5,
      'Flexi Loan': 7.0,
      'Stable Loan (12 months)': 5.0,
      'Stable Loan (18 months)': 7.0,
      'Premium Loan': 14.0,
      'Maxi Loan': 19.0
    };
    return rates[loanType] || 7.5;
  }

  /**
   * Get minimum interest floor for loan type
   */
  getMinimumInterestFloor(loanType) {
    const floors = {
      'Quick Loan': 5.0,
      'Flexi Loan': 6.0,
      'Stable Loan (12 months)': 5.0,
      'Stable Loan (18 months)': 6.0,
      'Premium Loan': 8.0,
      'Maxi Loan': 10.0
    };
    return floors[loanType] || 5.0;
  }

  /**
   * Log audit event
   */
  async logAuditEvent(action, referralId, userId, adminId, details, metadata = {}) {
    try {
      await AuditLog.log({
        action,
        referralId,
        userId,
        adminId,
        details,
        metadata
      });
    } catch (error) {
      logger.error('Error logging audit event:', error.message);
      // Don't throw - audit logging should not break main flow
    }
  }
}

module.exports = new ReferralService();
