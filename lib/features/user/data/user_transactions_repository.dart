import 'dart:typed_data';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/user_local_storage.dart';
import '../domain/models/user_models.dart';

class CouponValidationResult {
  const CouponValidationResult({
    required this.valid,
    required this.discountAmount,
    required this.message,
    this.coupon,
  });

  final bool valid;
  final int discountAmount;
  final String message;
  final UserCouponModel? coupon;
}

class UserTransactionsRepository {
  UserTransactionsRepository({
    required ApiClient userApiClient,
    required UserLocalStorage userStorage,
  })  : _api = userApiClient,
        _storage = userStorage;

  final ApiClient _api;
  final UserLocalStorage _storage;

  // ==========================================
  // ORDERS & COUPONS
  // ==========================================
  Future<List<UserOrderModel>> fetchMyOrders() async {
    final res = await _api.get('/user/orders');
    final raw = res['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(UserOrderModel.fromJson)
        .toList();
  }

  Future<UserOrderModel> createOrder({
    required String userName,
    required String userPhone,
    required String userEmail,
    required List<BookingCartItemModel> costumes,
    required String startDate,
    required int totalPrice,
    required int depositFee,
    required int discountAmount,
    String? couponCode,
    required String paymentMethod,
  }) async {
    final primary = costumes.first;
    final maxDuration = costumes.fold<int>(
      1,
      (prev, e) => e.days > prev ? e.days : prev,
    );
    final combinedNames = costumes.length == 1
        ? primary.name
        : '${primary.name} (+${costumes.length - 1} busana)';

    final res = await _api.post(
      '/user/orders',
      data: {
        'userName': userName.trim(),
        'userPhone': userPhone.trim(),
        'userEmail': userEmail.trim(),
        'costumeId': primary.id,
        'costumeName': combinedNames,
        'costumes': costumes.map((e) => e.toJson()).toList(),
        'startDate': startDate,
        'duration': maxDuration,
        'totalPrice': totalPrice,
        'depositFee': depositFee,
        'discountAmount': discountAmount,
        if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
        'status': 'Menunggu',
        'paymentMethod': paymentMethod,
      },
    );

    final raw = res['data'];
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(message: 'Respons pembuatan pesanan tidak valid.');
    }
    await _storage.clearBookingDraft();
    return UserOrderModel.fromJson(raw);
  }

  Future<void> cancelOrder(String orderId) async {
    await _api.patch(
      '/user/orders',
      data: {'orderId': orderId, 'status': 'Dibatalkan'},
    );
  }

  Future<String> uploadAndAttachPaymentProof({
    required String orderId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final uploadRes = await _api.uploadBytes(
      bytes: bytes,
      filename: filename,
      prefix: 'proof',
    );
    final url = (uploadRes['url'] ?? '').toString();
    if (url.isEmpty) {
      throw const ApiException(message: 'URL bukti bayar tidak diterima dari server.');
    }

    await _api.patch(
      '/user/orders',
      data: {'orderId': orderId, 'paymentProof': url},
    );
    return url;
  }

  Future<CouponValidationResult> validateCoupon({
    required String code,
    required int totalAmount,
  }) async {
    try {
      final res = await _api.post(
        '/user/coupons/validate',
        data: {'code': code.trim(), 'totalAmount': totalAmount},
      );
      final rawCoupon = res['coupon'];
      return CouponValidationResult(
        valid: true,
        discountAmount: (res['discountAmount'] as num?)?.toInt() ?? 0,
        message: (res['message'] ?? 'Kupon berhasil diterapkan.').toString(),
        coupon: rawCoupon is Map<String, dynamic>
            ? UserCouponModel.fromJson(rawCoupon)
            : null,
      );
    } on ApiException catch (e) {
      return CouponValidationResult(
        valid: false,
        discountAmount: 0,
        message: e.message,
      );
    }
  }

  // ==========================================
  // TICKETS & THEATER SEATS (WITH OFFLINE CACHE)
  // ==========================================
  Future<List<String>> fetchBookedSeats(String eventId) async {
    final res = await _api.get(
      '/user/tickets',
      queryParameters: {'eventId': eventId},
    );
    final raw = res['bookedSeats'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  Future<List<UserTicketModel>> fetchMyTickets() async {
    try {
      final res = await _api.get('/user/tickets');
      final raw = res['data'];
      if (raw is! List) return const [];
      final tickets = raw
          .whereType<Map<String, dynamic>>()
          .map(UserTicketModel.fromJson)
          .toList();
      await _storage.saveOfflineTicketsJson(
        tickets.map((t) => t.toJson()).toList(),
      );
      return tickets;
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        final cached = await _storage.getOfflineTicketsJson();
        if (cached.isNotEmpty) {
          return cached.map(UserTicketModel.fromJson).toList();
        }
      }
      rethrow;
    }
  }

  Future<UserTicketModel> bookTickets({
    required String eventId,
    required String eventTitle,
    required String userName,
    required String userPhone,
    required List<String> seats,
    required String zone,
    required int totalPrice,
  }) async {
    final res = await _api.post(
      '/user/tickets',
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
      throw const ApiException(message: 'Respons pemesanan tiket tidak valid.');
    }
    final ticket = UserTicketModel.fromJson(raw);

    final cached = await _storage.getOfflineTicketsJson();
    await _storage.saveOfflineTicketsJson([
      ticket.toJson(),
      ...cached.where((t) => t['id'] != ticket.id),
    ]);

    return ticket;
  }

  // ==========================================
  // PROFILE & SETTINGS
  // ==========================================
  Future<String> uploadAvatarBytes({
    required Uint8List bytes,
    required String filename,
  }) async {
    final uploadRes = await _api.uploadBytes(
      bytes: bytes,
      filename: filename,
      prefix: 'avatar',
    );
    final url = (uploadRes['url'] ?? '').toString();
    if (url.isEmpty) {
      throw const ApiException(
        message: 'URL foto profil tidak diterima dari server.',
      );
    }
    return url;
  }

  Future<UserAccountModel> updateProfile({
    required String name,
    required String phone,
    String? avatar,
  }) async {
    final res = await _api.patch(
      '/user/profile',
      data: {
        'name': name.trim(),
        'phone': phone.trim(),
        'avatar': ?avatar,
      },
    );
    final raw = res['data'];
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(message: 'Gagal memperbarui profil.');
    }
    final updated = UserAccountModel.fromJson(raw);
    await _storage.saveUserProfileJson(updated.toJson());
    return updated;
  }

  Future<PublicSettingsModel> fetchPublicSettings() async {
    final res = await _api.get('/user/settings');
    final raw = res['data'];
    if (raw is Map<String, dynamic>) {
      return PublicSettingsModel.fromJson(raw);
    }
    throw const ApiException(message: 'Pengaturan galeri tidak tersedia.');
  }
}
