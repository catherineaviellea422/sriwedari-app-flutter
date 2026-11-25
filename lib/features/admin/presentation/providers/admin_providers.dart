import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/admin_catalog_repository.dart';
import '../../data/admin_operations_repository.dart';
import '../../domain/models/admin_models.dart';

final adminCatalogRepositoryProvider = Provider<AdminCatalogRepository>((ref) {
  return AdminCatalogRepository(
    adminApiClient: ref.watch(adminApiClientProvider),
    adminStorage: ref.watch(adminLocalStorageProvider),
  );
});

class AdminAnalyticsNotifier extends AsyncNotifier<AnalyticsSummaryModel> {
  @override
  Future<AnalyticsSummaryModel> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAdmin) return const AnalyticsSummaryModel();
    return ref.watch(adminCatalogRepositoryProvider).fetchAnalytics();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminCatalogRepositoryProvider).fetchAnalytics(),
    );
  }
}

final adminAnalyticsProvider =
    AsyncNotifierProvider<AdminAnalyticsNotifier, AnalyticsSummaryModel>(
  AdminAnalyticsNotifier.new,
);

class AdminGalleriesNotifier extends AsyncNotifier<List<AdminGalleryModel>> {
  @override
  Future<List<AdminGalleryModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAdmin) return const [];
    return ref.watch(adminCatalogRepositoryProvider).fetchGalleries();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminCatalogRepositoryProvider).fetchGalleries(),
    );
  }
}

final adminGalleriesProvider =
    AsyncNotifierProvider<AdminGalleriesNotifier, List<AdminGalleryModel>>(
  AdminGalleriesNotifier.new,
);

class AdminCategoriesNotifier extends AsyncNotifier<List<AdminCategoryModel>> {
  @override
  Future<List<AdminCategoryModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAdmin) return const [];
    return ref.watch(adminCatalogRepositoryProvider).fetchCategories();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminCatalogRepositoryProvider).fetchCategories(),
    );
  }
}

final adminCategoriesProvider =
    AsyncNotifierProvider<AdminCategoriesNotifier, List<AdminCategoryModel>>(
  AdminCategoriesNotifier.new,
);

class AdminCostumesNotifier extends AsyncNotifier<List<AdminCostumeModel>> {
  @override
  Future<List<AdminCostumeModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAdmin) return const [];
    return ref.watch(adminCatalogRepositoryProvider).fetchCostumes();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminCatalogRepositoryProvider).fetchCostumes(),
    );
  }
}

final adminCostumesProvider =
    AsyncNotifierProvider<AdminCostumesNotifier, List<AdminCostumeModel>>(
  AdminCostumesNotifier.new,
);

final adminStockMovementsProvider =
    FutureProvider.family<List<StockMovementModel>, String?>((ref, costumeId) {
  return ref
      .watch(adminCatalogRepositoryProvider)
      .fetchStockMovements(costumeId: costumeId);
});

class AdminEventsNotifier extends AsyncNotifier<List<AdminEventModel>> {
  @override
  Future<List<AdminEventModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAdmin) return const [];
    return ref.watch(adminCatalogRepositoryProvider).fetchEvents();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminCatalogRepositoryProvider).fetchEvents(),
    );
  }
}

final adminEventsProvider =
    AsyncNotifierProvider<AdminEventsNotifier, List<AdminEventModel>>(
  AdminEventsNotifier.new,
);

class AdminOrdersNotifier extends AsyncNotifier<List<AdminOrderQcModel>> {
  @override
  Future<List<AdminOrderQcModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAdmin) return const [];
    return ref.watch(adminCatalogRepositoryProvider).fetchOrders();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminCatalogRepositoryProvider).fetchOrders(),
    );
  }
}

final adminOrdersProvider =
    AsyncNotifierProvider<AdminOrdersNotifier, List<AdminOrderQcModel>>(
  AdminOrdersNotifier.new,
);

// ==========================================
// FASE 6: OPERATIONS PROVIDERS (POS, VISITORS, COUPONS, REVIEWS, USERS, AUDIT, SETTINGS)
// ==========================================

final adminOperationsRepositoryProvider =
    Provider<AdminOperationsRepository>((ref) {
  return AdminOperationsRepository(
    adminApiClient: ref.watch(adminApiClientProvider),
    adminStorage: ref.watch(adminLocalStorageProvider),
  );
});

class AdminTicketsNotifier extends AsyncNotifier<List<AdminTicketGateModel>> {
  @override
  Future<List<AdminTicketGateModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAdmin) return const [];
    return ref.watch(adminOperationsRepositoryProvider).fetchTickets();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminOperationsRepositoryProvider).fetchTickets(),
    );
  }
}

final adminTicketsProvider =
    AsyncNotifierProvider<AdminTicketsNotifier, List<AdminTicketGateModel>>(
  AdminTicketsNotifier.new,
);

final adminEventBookedSeatsProvider =
    FutureProvider.family<List<String>, String>((ref, eventId) {
  return ref
      .watch(adminOperationsRepositoryProvider)
      .fetchBookedSeats(eventId);
});

class AdminCouponsNotifier extends AsyncNotifier<List<AdminCouponModel>> {
  @override
  Future<List<AdminCouponModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAdmin) return const [];
    return ref.watch(adminOperationsRepositoryProvider).fetchCoupons();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminOperationsRepositoryProvider).fetchCoupons(),
    );
  }
}

final adminCouponsProvider =
    AsyncNotifierProvider<AdminCouponsNotifier, List<AdminCouponModel>>(
  AdminCouponsNotifier.new,
);

class AdminReviewsNotifier
    extends AsyncNotifier<List<AdminReviewModerationModel>> {
  @override
  Future<List<AdminReviewModerationModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAdmin) return const [];
    return ref.watch(adminOperationsRepositoryProvider).fetchReviews();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminOperationsRepositoryProvider).fetchReviews(),
    );
  }
}

final adminReviewsProvider = AsyncNotifierProvider<AdminReviewsNotifier,
    List<AdminReviewModerationModel>>(
  AdminReviewsNotifier.new,
);

class AdminUsersNotifier extends AsyncNotifier<List<AdminAccountModel>> {
  @override
  Future<List<AdminAccountModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAdmin) return const [];
    return ref.watch(adminOperationsRepositoryProvider).fetchUsers();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminOperationsRepositoryProvider).fetchUsers(),
    );
  }
}

final adminUsersProvider =
    AsyncNotifierProvider<AdminUsersNotifier, List<AdminAccountModel>>(
  AdminUsersNotifier.new,
);

class AdminAuditLogsNotifier extends AsyncNotifier<List<AuditLogModel>> {
  @override
  Future<List<AuditLogModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAdmin) return const [];
    return ref.watch(adminOperationsRepositoryProvider).fetchAuditLogs();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminOperationsRepositoryProvider).fetchAuditLogs(),
    );
  }
}

final adminAuditLogsProvider =
    AsyncNotifierProvider<AdminAuditLogsNotifier, List<AuditLogModel>>(
  AdminAuditLogsNotifier.new,
);

class AdminSettingsNotifier extends AsyncNotifier<SystemSettingsModel> {
  @override
  Future<SystemSettingsModel> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAdmin) {
      return const SystemSettingsModel(
        galleryName: 'Galeri Sriwedari',
        tagline: '',
        openHours: '',
        location: '',
        phone: '',
        email: '',
        depositFee: 100000,
        terms: '',
      );
    }
    return ref.watch(adminOperationsRepositoryProvider).fetchSettings();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminOperationsRepositoryProvider).fetchSettings(),
    );
  }
}

final adminSettingsProvider =
    AsyncNotifierProvider<AdminSettingsNotifier, SystemSettingsModel>(
  AdminSettingsNotifier.new,
);

typedef CsvFileSaver = Future<void> Function(String baseName, Uint8List bytes);

final csvFileSaverProvider = Provider<CsvFileSaver>((ref) {
  return (baseName, bytes) async {
    await FileSaver.instance.saveFile(
      name: baseName,
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  };
});

