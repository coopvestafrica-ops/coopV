import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/referral_models.dart';
import '../../core/network/api_client.dart';
import 'package:dio/dio.dart';

/// API Service for Referral Operations

class ReferralApiService {
  final Dio _dio;
  ReferralApiService(this._dio);

  /// Get user's referral summary

  Future<ReferralSummaryResponse> getReferralSummary() => Future.value(
    ReferralSummaryResponse(
      success: true,
      summary: null,
    ),
  );

  /// Get user's referral code

  Future<ReferralCodeResponse> getMyReferralCode() => Future.value(
    ReferralCodeResponse(
      success: true,
      referralCode: '',
    ),
  );

  /// Get all user's referrals

  Future<ReferralListResponse> getMyReferrals() => Future.value(
    ReferralListResponse(
      success: true,
      referrals: [],
      total: 0,
      page: 1,
      limit: 20,
    ),
  );

  /// Get referral by ID

  Future<ReferralDetailResponse> getReferralById(String referralId,
  ) => Future.value(
    ReferralDetailResponse(
      success: true,
      referral: null,
    ),
  );

  /// Register a new referral (when new user registers with code)

  Future<ReferralDetailResponse> registerReferral(ReferralRegisterRequest request,
  ) => Future.value(
    ReferralDetailResponse(
      success: true,
      referral: null,
    ),
  );

  /// Check referral status and qualification

  Future<ReferralStatusResponse> checkReferralStatus(String referralId,
  ) => Future.value(
    ReferralStatusResponse(
      success: true,
      qualified: false,
      kycVerified: false,
      savingsCriteriaMet: false,
      consecutiveSavingsMonths: 0,
      requiredSavingsMonths: 3,
      isFlagged: false,
    ),
  );

  /// Trigger referral confirmation process (after qualification met)

  Future<ReferralDetailResponse> confirmReferral(String referralId,
  ) => Future.value(
    ReferralDetailResponse(
      success: true,
      referral: null,
    ),
  );

  /// Apply referral bonus to a loan

  Future<ApplyBonusResponse> applyBonusToLoan(ApplyBonusRequest request,
  ) => Future.value(
    ApplyBonusResponse(
      success: true,
      bonusPercent: 0.0,
      loanId: '',
    ),
  );

  /// Get loan interest calculation with referral bonus

  Future<InterestCalculationResponse> calculateInterestWithBonus(InterestCalculationRequest request,
  ) => Future.value(
    InterestCalculationResponse(
      success: true,
      calculation: null,
    ),
  );

  /// Share referral link

  Future<ShareLinkResponse> getShareLink() => Future.value(
    ShareLinkResponse(
      success: true,
      shareLink: '',
      referralCode: '',
    ),
  );

  // ============== Admin Endpoints ==============

  /// Get all referrals (admin)
  Future<ReferralListResponse> getAllReferralsAdmin({
    String? status,
    int? page,
    int? limit,
  }) => Future.value(ReferralListResponse(
    success: true,
    referrals: [],
    total: 0,
    page: page ?? 1,
    limit: limit ?? 20,
  ));

  /// Get referral statistics (admin)
  Future<ReferralStatsResponse> getReferralStatsAdmin() => Future.value(ReferralStatsResponse(
    success: true,
    totalReferrals: 0,
    pendingReferrals: 0,
    confirmedReferrals: 0,
    flaggedReferrals: 0,
    referralsByTier: {},
    totalBonusesApplied: {},
    totalInterestSaved: 0.0,
  ));

  /// Manually confirm a referral (admin)
  Future<ReferralDetailResponse> adminConfirmReferral(String referralId, AdminConfirmRequest request,
  ) => Future.value(ReferralDetailResponse(success: true));

  /// Flag a referral for review (admin)
  Future<ReferralDetailResponse> adminFlagReferral(String referralId, FlagReferralRequest request,
  ) => Future.value(ReferralDetailResponse(success: true));

  /// Unflag a referral (admin)
  Future<ReferralDetailResponse> adminUnflagReferral(String referralId,
  ) => Future.value(ReferralDetailResponse(success: true));

  /// Revoke referral bonus (admin)
  Future<ReferralDetailResponse> adminRevokeBonus(String referralId, RevokeBonusRequest request,
  ) => Future.value(ReferralDetailResponse(success: true));

  /// Get audit logs (admin)
  Future<AuditLogResponse> getAuditLogs({
    int? page,
    int? limit,
  }) => Future.value(AuditLogResponse(success: true, logs: [], total: 0, page: 1));

  /// Update referral settings (admin)
  Future<SettingsResponse> updateReferralSettings(ReferralSettingsRequest request,
  ) => Future.value(SettingsResponse(success: true, enabled: true, lockInDays: 0, minimumSavingsMonths: 0));

  /// Get referral settings (admin)
  Future<SettingsResponse> getReferralSettings() => Future.value(SettingsResponse(success: true, enabled: true, lockInDays: 0, minimumSavingsMonths: 0));
}

/// Referral API Service Provider
final referralApiServiceProvider = Provider<ReferralApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReferralApiService(apiClient.dio);
});

// ============== Request Models ==============

class ReferralRegisterRequest {
  final String referralCode;
  final String referredUserId;

  ReferralRegisterRequest({
    required this.referralCode,
    required this.referredUserId,
  });

  Map<String, dynamic> toJson() => {
        'referral_code': referralCode,
        'referred_user_id': referredUserId,
      };
}

class ApplyBonusRequest {
  final String loanId;
  final String userId;

  ApplyBonusRequest({
    required this.loanId,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
        'loan_id': loanId,
        'user_id': userId,
      };
}

class InterestCalculationRequest {
  final String loanType;
  final double loanAmount;
  final int tenureMonths;
  final String? userId;

  InterestCalculationRequest({
    required this.loanType,
    required this.loanAmount,
    required this.tenureMonths,
    this.userId,
  });

  Map<String, dynamic> toJson() => {
        'loan_type': loanType,
        'loan_amount': loanAmount,
        'tenure_months': tenureMonths,
        'user_id': userId,
      };
}

class AdminConfirmRequest {
  final String adminId;
  final String? notes;

  AdminConfirmRequest({
    required this.adminId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'admin_id': adminId,
        'notes': notes,
      };
}

class FlagReferralRequest {
  final String reason;
  final String adminId;

  FlagReferralRequest({
    required this.reason,
    required this.adminId,
  });

  Map<String, dynamic> toJson() => {
        'reason': reason,
        'admin_id': adminId,
      };
}

class RevokeBonusRequest {
  final String reason;
  final String adminId;

  RevokeBonusRequest({
    required this.reason,
    required this.adminId,
  });

  Map<String, dynamic> toJson() => {
        'reason': reason,
        'admin_id': adminId,
      };
}

class ReferralSettingsRequest {
  final bool enabled;
  final int lockInDays;
  final int minimumSavingsMonths;
  final double? minimumSavingsAmount;
  final Map<String, double>? minimumInterestFloors;

  ReferralSettingsRequest({
    required this.enabled,
    required this.lockInDays,
    required this.minimumSavingsMonths,
    this.minimumSavingsAmount,
    this.minimumInterestFloors,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'lock_in_days': lockInDays,
        'minimum_savings_months': minimumSavingsMonths,
        'minimum_savings_amount': minimumSavingsAmount,
        'minimum_interest_floors': minimumInterestFloors,
      };
}

// ============== Response Models ==============

class ReferralSummaryResponse {
  final bool success;
  final String? error;
  final ReferralSummary? summary;

  ReferralSummaryResponse({
    required this.success,
    this.error,
    this.summary,
  });

  factory ReferralSummaryResponse.fromJson(Map<String, dynamic> json) {
    return ReferralSummaryResponse(
      success: json['success'] as bool,
      error: json['error'] as String?,
      summary: json['summary'] != null
          ? ReferralSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ReferralCodeResponse {
  final bool success;
  final String? error;
  final String? referralCode;
  final String? qrCodeUrl;

  ReferralCodeResponse({
    required this.success,
    this.error,
    this.referralCode,
    this.qrCodeUrl,
  });

  factory ReferralCodeResponse.fromJson(Map<String, dynamic> json) {
    return ReferralCodeResponse(
      success: json['success'] as bool,
      error: json['error'] as String?,
      referralCode: json['referral_code'] as String?,
      qrCodeUrl: json['qr_code_url'] as String?,
    );
  }
}

class ReferralListResponse {
  final bool success;
  final String? error;
  final List<Referral> referrals;
  final int total;
  final int page;
  final int limit;

  ReferralListResponse({
    required this.success,
    this.error,
    required this.referrals,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory ReferralListResponse.fromJson(Map<String, dynamic> json) {
    return ReferralListResponse(
      success: json['success'] as bool,
      error: json['error'] as String?,
      referrals: (json['referrals'] as List<dynamic>)
          .map((e) => Referral.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
    );
  }
}

class ReferralDetailResponse {
  final bool success;
  final String? error;
  final Referral? referral;

  ReferralDetailResponse({
    required this.success,
    this.error,
    this.referral,
  });

  factory ReferralDetailResponse.fromJson(Map<String, dynamic> json) {
    return ReferralDetailResponse(
      success: json['success'] as bool,
      error: json['error'] as String?,
      referral: json['referral'] != null
          ? Referral.fromJson(json['referral'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ReferralStatusResponse {
  final bool success;
  final String? error;
  final bool qualified;
  final bool kycVerified;
  final bool savingsCriteriaMet;
  final int consecutiveSavingsMonths;
  final int requiredSavingsMonths;
  final bool isFlagged;
  final String? flagReason;
  final String? message;

  ReferralStatusResponse({
    required this.success,
    this.error,
    required this.qualified,
    required this.kycVerified,
    required this.savingsCriteriaMet,
    required this.consecutiveSavingsMonths,
    required this.requiredSavingsMonths,
    required this.isFlagged,
    this.flagReason,
    this.message,
  });

  factory ReferralStatusResponse.fromJson(Map<String, dynamic> json) {
    return ReferralStatusResponse(
      success: json['success'] as bool,
      error: json['error'] as String?,
      qualified: json['qualified'] as bool? ?? false,
      kycVerified: json['kyc_verified'] as bool? ?? false,
      savingsCriteriaMet: json['savings_criteria_met'] as bool? ?? false,
      consecutiveSavingsMonths: json['consecutive_savings_months'] as int? ?? 0,
      requiredSavingsMonths: json['required_savings_months'] as int? ?? 3,
      isFlagged: json['is_flagged'] as bool? ?? false,
      flagReason: json['flag_reason'] as String?,
      message: json['message'] as String?,
    );
  }
}

class ApplyBonusResponse {
  final bool success;
  final String? error;
  final double bonusPercent;
  final String loanId;
  final DateTime? appliedAt;

  ApplyBonusResponse({
    required this.success,
    this.error,
    required this.bonusPercent,
    required this.loanId,
    this.appliedAt,
  });

  factory ApplyBonusResponse.fromJson(Map<String, dynamic> json) {
    return ApplyBonusResponse(
      success: json['success'] as bool,
      error: json['error'] as String?,
      bonusPercent: (json['bonus_percent'] as num).toDouble(),
      loanId: json['loan_id'] as String,
      appliedAt: json['applied_at'] != null
          ? DateTime.parse(json['applied_at'] as String)
          : null,
    );
  }
}

class InterestCalculationResponse {
  final bool success;
  final String? error;
  final LoanInterestCalculation? calculation;

  InterestCalculationResponse({
    required this.success,
    this.error,
    this.calculation,
  });

  factory InterestCalculationResponse.fromJson(Map<String, dynamic> json) {
    return InterestCalculationResponse(
      success: json['success'] as bool,
      error: json['error'] as String?,
      calculation: json['calculation'] != null
          ? LoanInterestCalculation.fromJson(json['calculation'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ShareLinkResponse {
  final bool success;
  final String? error;
  final String? shareLink;
  final String? referralCode;
  final String? qrCodeUrl;

  ShareLinkResponse({
    required this.success,
    this.error,
    this.shareLink,
    this.referralCode,
    this.qrCodeUrl,
  });

  factory ShareLinkResponse.fromJson(Map<String, dynamic> json) {
    return ShareLinkResponse(
      success: json['success'] as bool,
      error: json['error'] as String?,
      shareLink: json['share_link'] as String?,
      referralCode: json['referral_code'] as String?,
      qrCodeUrl: json['qr_code_url'] as String?,
    );
  }
}

class ReferralStatsResponse {
  final bool success;
  final String? error;
  final int totalReferrals;
  final int pendingReferrals;
  final int confirmedReferrals;
  final int flaggedReferrals;
  final Map<String, int> referralsByTier;
  final Map<String, double> totalBonusesApplied;
  final double totalInterestSaved;

  ReferralStatsResponse({
    required this.success,
    this.error,
    required this.totalReferrals,
    required this.pendingReferrals,
    required this.confirmedReferrals,
    required this.flaggedReferrals,
    required this.referralsByTier,
    required this.totalBonusesApplied,
    required this.totalInterestSaved,
  });

  factory ReferralStatsResponse.fromJson(Map<String, dynamic> json) {
    return ReferralStatsResponse(
      success: json['success'] as bool,
      error: json['error'] as String?,
      totalReferrals: json['total_referrals'] as int? ?? 0,
      pendingReferrals: json['pending_referrals'] as int? ?? 0,
      confirmedReferrals: json['confirmed_referrals'] as int? ?? 0,
      flaggedReferrals: json['flagged_referrals'] as int? ?? 0,
      referralsByTier: Map<String, int>.from(json['referrals_by_tier'] as Map? ?? {}),
      totalBonusesApplied: Map<String, double>.from(json['total_bonuses_applied'] as Map? ?? {}),
      totalInterestSaved: (json['total_interest_saved'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AuditLogResponse {
  final bool success;
  final String? error;
  final List<AuditLogEntry> logs;
  final int total;
  final int page;

  AuditLogResponse({
    required this.success,
    this.error,
    required this.logs,
    required this.total,
    required this.page,
  });

  factory AuditLogResponse.fromJson(Map<String, dynamic> json) {
    return AuditLogResponse(
      success: json['success'] as bool,
      error: json['error'] as String?,
      logs: (json['logs'] as List<dynamic>)
          .map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
    );
  }
}

class AuditLogEntry {
  final String id;
  final String action;
  final String referralId;
  final String? userId;
  final String? adminId;
  final String details;
  final DateTime createdAt;

  AuditLogEntry({
    required this.id,
    required this.action,
    required this.referralId,
    this.userId,
    this.adminId,
    required this.details,
    required this.createdAt,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String,
      action: json['action'] as String,
      referralId: json['referral_id'] as String,
      userId: json['user_id'] as String?,
      adminId: json['admin_id'] as String?,
      details: json['details'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SettingsResponse {
  final bool success;
  final String? error;
  final bool enabled;
  final int lockInDays;
  final int minimumSavingsMonths;
  final double? minimumSavingsAmount;
  final Map<String, double>? minimumInterestFloors;

  SettingsResponse({
    required this.success,
    this.error,
    required this.enabled,
    required this.lockInDays,
    required this.minimumSavingsMonths,
    this.minimumSavingsAmount,
    this.minimumInterestFloors,
  });

  factory SettingsResponse.fromJson(Map<String, dynamic> json) {
    return SettingsResponse(
      success: json['success'] as bool,
      error: json['error'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      lockInDays: json['lock_in_days'] as int? ?? 30,
      minimumSavingsMonths: json['minimum_savings_months'] as int? ?? 3,
      minimumSavingsAmount: json['minimum_savings_amount'] != null
          ? (json['minimum_savings_amount'] as num).toDouble()
          : null,
      minimumInterestFloors: json['minimum_interest_floors'] != null
          ? Map<String, double>.from(json['minimum_interest_floors'] as Map)
          : null,
    );
  }
}

