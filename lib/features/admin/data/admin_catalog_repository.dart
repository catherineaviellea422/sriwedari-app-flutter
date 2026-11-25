import 'dart:typed_data';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/admin_local_storage.dart';
import '../domain/models/admin_models.dart';

class AdminCatalogRepository {
  AdminCatalogRepository({
    required ApiClient adminApiClient,
    required AdminLocalStorage adminStorage,
  })  : _api = adminApiClient,
        _storage = adminStorage;

  final ApiClient _api;
  final AdminLocalStorage _storage;

  // ==========================================
  // ANALYTICS (CACHE-SUPPORTED)
  // ==========================================
  Future<AnalyticsSummaryModel> fetchAnalytics() async {
    try {
      final res = await _api.get('/admin/analytics');
      final raw = res['data'];
      if (raw is! Map<String, dynamic>) {
        throw const ApiException(message: 'Data analitik admin tidak valid.');
      }
      final summary = AnalyticsSummaryModel.fromJson(raw);
      await _storage.saveAnalyticsCacheJson(summary.toJson());
      await _storage.setLastSyncAt(DateTime.now().toIso8601String());
      return summary;
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        final cached = await _storage.getAnalyticsCacheJson();
        if (cached != null) {
          return AnalyticsSummaryModel.fromJson(cached);
        }
      }
      rethrow;
    }
  }

  // ==========================================
  // MEDIA UPLOAD
  // ==========================================
  Future<String> uploadMediaBytes({
    required Uint8List bytes,
    required String filename,
    String prefix = 'admin-media',
  }) async {
    final res = await _api.uploadBytes(
      bytes: bytes,
      filename: filename,
      prefix: prefix,
    );
    final url = (res['url'] ?? '').toString();
    if (url.isEmpty) {
      throw const ApiException(message: 'Server tidak mengembalikan URL berkas.');
    }
    return url;
  }

  // ==========================================
  // GALLERIES CRUD
  // ==========================================
  Future<List<AdminGalleryModel>> fetchGalleries() async {
    final res = await _api.get('/admin/galleries');
    final raw = res['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AdminGalleryModel.fromJson)
        .toList();
  }

  Future<AdminGalleryModel> saveGallery(AdminGalleryModel gallery) async {
    final res = await _api.post('/admin/galleries', data: gallery.toJson());
    final raw = res['data'];
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(message: 'Gagal menyimpan karya galeri.');
    }
    return AdminGalleryModel.fromJson(raw);
  }

  Future<void> deleteGallery(String id) async {
    await _api.delete('/admin/galleries', queryParameters: {'id': id});
  }

  // ==========================================
  // CATEGORIES CRUD
  // ==========================================
  Future<List<AdminCategoryModel>> fetchCategories() async {
    final res = await _api.get('/admin/categories');
    final raw = res['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AdminCategoryModel.fromJson)
        .toList();
  }

  Future<AdminCategoryModel> saveCategory(AdminCategoryModel category) async {
    final res = await _api.post('/admin/categories', data: category.toJson());
    final raw = res['data'];
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(message: 'Gagal menyimpan kategori.');
    }
    return AdminCategoryModel.fromJson(raw);
  }

  Future<void> deleteCategory(String id) async {
    await _api.delete('/admin/categories', queryParameters: {'id': id});
  }

  // ==========================================
  // COSTUMES CRUD & STOCK MOVEMENTS
  // ==========================================
  Future<List<AdminCostumeModel>> fetchCostumes() async {
    final res = await _api.get('/admin/costumes');
    final raw = res['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AdminCostumeModel.fromJson)
        .toList();
  }

  Future<AdminCostumeModel> saveCostume(AdminCostumeModel costume) async {
    final res = await _api.post('/admin/costumes', data: costume.toJson());
    final raw = res['data'];
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(message: 'Gagal menyimpan data kostum.');
    }
    return AdminCostumeModel.fromJson(raw);
  }

  Future<void> deleteCostume(String id) async {
    await _api.delete('/admin/costumes', queryParameters: {'id': id});
  }

  Future<List<StockMovementModel>> fetchStockMovements({
    String? costumeId,
  }) async {
    final res = await _api.get(
      '/admin/stock-movements',
      queryParameters: costumeId != null && costumeId.isNotEmpty
          ? {'costumeId': costumeId}
          : null,
    );
    final raw = res['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(StockMovementModel.fromJson)
        .toList();
  }

  Future<StockMovementModel> recordStockMovement({
    required String costumeId,
    required String costumeName,
    required String size,
    required int delta,
    required int stockAfter,
    required String reason,
    String? note,
  }) async {
    final res = await _api.post(
      '/admin/stock-movements',
      data: {
        'costumeId': costumeId,
        'costumeName': costumeName,
        'size': size,
        'delta': delta,
        'stockAfter': stockAfter < 0 ? 0 : stockAfter,
        'reason': reason,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    final raw = res['data'];
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(message: 'Gagal mencatat mutasi stok.');
    }
    return StockMovementModel.fromJson(raw);
  }

  // ==========================================
  // EVENTS CRUD
  // ==========================================
  Future<List<AdminEventModel>> fetchEvents() async {
    final res = await _api.get('/admin/events');
    final raw = res['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AdminEventModel.fromJson)
        .toList();
  }

  Future<AdminEventModel> saveEvent(AdminEventModel event) async {
    final res = await _api.post('/admin/events', data: event.toJson());
    final raw = res['data'];
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(message: 'Gagal menyimpan jadwal acara.');
    }
    return AdminEventModel.fromJson(raw);
  }

  Future<void> deleteEvent(String id) async {
    await _api.delete('/admin/events', queryParameters: {'id': id});
  }

  // ==========================================
  // ORDERS QUEUE & QC ENGINE
  // ==========================================
  Future<List<AdminOrderQcModel>> fetchOrders() async {
    final res = await _api.get('/admin/orders');
    final raw = res['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AdminOrderQcModel.fromJson)
        .toList();
  }

  Future<AdminOrderQcModel> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final res = await _api.patch(
      '/admin/orders',
      data: {'orderId': orderId, 'status': status},
    );
    final raw = res['data'];
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(message: 'Gagal memperbarui status pesanan.');
    }
    return AdminOrderQcModel.fromJson(raw);
  }

  Future<AdminOrderQcModel> submitOrderQc({
    required String orderId,
    required String qcStatus,
    required int refundAmount,
    String? deductionNote,
  }) async {
    final res = await _api.patch(
      '/admin/orders',
      data: {
        'orderId': orderId,
        'qcStatus': qcStatus,
        'refundAmount': refundAmount,
        if (deductionNote != null && deductionNote.trim().isNotEmpty)
          'deductionNote': deductionNote.trim(),
      },
    );
    final raw = res['data'];
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(message: 'Gagal menyimpan inspeksi QC.');
    }
    return AdminOrderQcModel.fromJson(raw);
  }

  Future<String?> getSavedOrderFilter() => _storage.getOrderFilterStatus();

  Future<void> saveOrderFilter(String status) =>
      _storage.setOrderFilterStatus(status);
}
