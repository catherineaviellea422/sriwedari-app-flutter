import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/admin_local_storage.dart';
import '../domain/models/admin_models.dart';

class GateValidationResult {
  const GateValidationResult({
    required this.success,
    required this.message,
    this.ticket,
  });

  final bool success;
  final String message;
  final AdminTicketGateModel? ticket;
}

class AdminOperationsRepository {
  AdminOperationsRepository({
    required ApiClient adminApiClient,
    required AdminLocalStorage adminStorage,
  })  : _api = adminApiClient,
        _storage = adminStorage;

  final ApiClient _api;
  final AdminLocalStorage _storage;

  // ==========================================
  // TICKETS, POS & GATE CHECK-IN
  // ==========================================
  Future<List<AdminTicketGateModel>> fetchTickets() async {
    final res = await _api.get('/admin/tickets');
    final raw = res['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AdminTicketGateModel.fromJson)
        .toList();
  }

  Future<List<String>> fetchBookedSeats(String eventId) async {
    final res = await _api.get(
      '/admin/tickets',
      queryParameters: {'eventId': eventId},
    );
    final raw = res['bookedSeats'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  Future<AdminTicketGateModel> issuePosTicket({
    required String eventId,
    required String eventTitle,
    required String userName,
    required String userPhone,
    required List<String> seats,
    required String zone,
    required int totalPrice,
  }) async {
    final res = await _api.post(
      '/admin/tickets',
      data: {
        'eventId': eventId,
        'eventTitle': eventTitle,
        'userName': userName.trim(),
        'userPhone': userPhone.trim(),
        'quantity': seats.length,
        'seats': seats,
        'zone': zone,
        'totalPrice': totalPrice,
        'status': 'Aktif',
      },
    );

    final raw = res['ticket'];
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Respons penerbitan tiket loket tidak valid.',
      );
    }
    return AdminTicketGateModel.fromJson(raw);
  }

  Future<GateValidationResult> validateGateTicket(String ticketCode) async {
    final cleanCode = ticketCode.trim().toUpperCase();
    try {
      final res = await _api.patch(
        '/admin/tickets',
        data: {'ticketCode': cleanCode},
      );
      final rawTicket = res['ticket'];
      final ticket = rawTicket is Map<String, dynamic>
          ? AdminTicketGateModel.fromJson(rawTicket)
          : null;
      final message = (res['message'] ?? 'Check-in berhasil.').toString();

      await _storage.appendGateScanHistoryJson({
        'code': ticket?.bookingCode ?? cleanCode,
        'userName': ticket?.userName ?? '-',
        'zone': ticket?.zone ?? '-',
        'seats': ticket?.seats.join(', ') ?? '-',
        'success': true,
        'message': message,
        'scannedAt': DateTime.now().toIso8601String(),
      });

      return GateValidationResult(
        success: true,
        message: message,
        ticket: ticket,
      );
    } on ApiException catch (e) {
      await _storage.appendGateScanHistoryJson({
        'code': cleanCode,
        'userName': '-',
        'zone': '-',
        'seats': '-',
        'success': false,
        'message': e.message,
        'scannedAt': DateTime.now().toIso8601String(),
      });
      return GateValidationResult(
        success: false,
        message: e.message,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getLocalScanHistory() =>
      _storage.getGateScanHistoryJson();

  Future<String?> getSavedPosEventId() => _storage.getSelectedPosEventId();

  Future<void> savePosEventId(String eventId) =>
      _storage.setSelectedPosEventId(eventId);

  // ==========================================
  // COUPONS CRUD
  // ==========================================
  Future<List<AdminCouponModel>> fetchCoupons() async {
    final res = await _api.get('/admin/coupons');
    final raw = res['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AdminCouponModel.fromJson)
        .toList();
  }

  Future<AdminCouponModel> saveCoupon(AdminCouponModel coupon) async {
    final res = await _api.post('/admin/coupons', data: coupon.toJson());
    final raw = res['data'];
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(message: 'Gagal menyimpan kupon promo.');
    }
    return AdminCouponModel.fromJson(raw);
  }

  Future<void> deleteCoupon(String id) async {
    await _api.delete('/admin/coupons', queryParameters: {'id': id});
  }

  // ==========================================
  // REVIEWS MODERATION
  // ==========================================
  Future<List<AdminReviewModerationModel>> fetchReviews() async {
    final res = await _api.get('/admin/reviews');
    final raw = res['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AdminReviewModerationModel.fromJson)
        .toList();
  }

  Future<AdminReviewModerationModel> updateReviewStatus({
    required String id,
    required String status,
  }) async {
    final res = await _api.patch(
      '/admin/reviews',
      data: {'id': id, 'status': status},
    );
    final raw = res['data'];
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(message: 'Gagal memperbarui status ulasan.');
    }
    return AdminReviewModerationModel.fromJson(raw);
  }

  Future<void> deleteReview(String id) async {
    await _api.delete('/admin/reviews', queryParameters: {'id': id});
  }

  // ==========================================
  // USERS & CURATORS CRUD
  // ==========================================
  Future<List<AdminAccountModel>> fetchUsers() async {
    final res = await _api.get('/admin/users');
    final raw = res['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AdminAccountModel.fromJson)
        .toList();
  }

  Future<AdminAccountModel> saveUser(
    AdminAccountModel user, {
    String? password,
  }) async {
    final payload = {
      ...user.toJson(),
      if (password != null && password.trim().isNotEmpty)
        'password': password.trim(),
    };
    final res = await _api.post('/admin/users', data: payload);
    final raw = res['data'];
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(message: 'Gagal menyimpan akun pengguna.');
    }
    return AdminAccountModel.fromJson(raw);
  }

  Future<void> deleteUser(String id) async {
    await _api.delete('/admin/users', queryParameters: {'id': id});
  }

  // ==========================================
  // AUDIT TRAIL & CSV EXPORT
  // ==========================================
  Future<List<AuditLogModel>> fetchAuditLogs() async {
    final res = await _api.get('/admin/audit');
    final raw = res['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AuditLogModel.fromJson)
        .toList();
  }

  Future<String> exportAuditCsvRaw() {
    return _api.getRawText(
      '/admin/audit',
      queryParameters: {'format': 'csv'},
    );
  }

  // ==========================================
  // SYSTEM SETTINGS & RESET DB
  // ==========================================
  Future<SystemSettingsModel> fetchSettings() async {
    final res = await _api.get('/admin/settings');
    final raw = res['data'];
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(message: 'Pengaturan sistem tidak valid.');
    }
    return SystemSettingsModel.fromJson(raw);
  }

  Future<SystemSettingsModel> saveSettings(SystemSettingsModel settings) async {
    final res = await _api.post('/admin/settings', data: settings.toJson());
    final raw = res['data'];
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(message: 'Gagal menyimpan pengaturan.');
    }
    return SystemSettingsModel.fromJson(raw);
  }

  Future<String> resetDatabase() async {
    final res = await _api.put('/admin/settings');
    return (res['message'] ?? 'Basis data berhasil direset.').toString();
  }
}
