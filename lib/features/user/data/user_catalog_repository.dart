import '../../../core/network/api_client.dart';
import '../../../core/storage/user_local_storage.dart';
import '../domain/models/user_models.dart';

class UserCatalogRepository {
  UserCatalogRepository({
    required ApiClient userApiClient,
    required UserLocalStorage userStorage,
  })  : _api = userApiClient,
        _storage = userStorage;

  final ApiClient _api;
  final UserLocalStorage _storage;

  Future<List<UserGalleryModel>> fetchGalleries() async {
    final res = await _api.get('/user/galleries');
    final rawList = res['data'];
    if (rawList is! List) return const [];
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(UserGalleryModel.fromJson)
        .toList();
  }

  Future<UserGalleryModel> fetchGalleryById(String id) async {
    final res = await _api.get('/user/galleries', queryParameters: {'id': id});
    final raw = res['data'];
    if (raw is Map<String, dynamic>) {
      return UserGalleryModel.fromJson(raw);
    }
    throw Exception('Data karya galeri tidak ditemukan.');
  }

  Future<({bool isLiked, int likes})> toggleGalleryLike(String id) async {
    final res = await _api.patch('/user/galleries/like', data: {'id': id});
    return (
      isLiked: res['isLiked'] == true,
      likes: (res['likes'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<UserCategoryModel>> fetchCategories() async {
    final res = await _api.get('/user/categories');
    final rawList = res['data'];
    if (rawList is! List) return const [];
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(UserCategoryModel.fromJson)
        .toList();
  }

  Future<List<UserCostumeModel>> fetchCostumes() async {
    final res = await _api.get('/user/costumes');
    final rawList = res['data'];
    if (rawList is! List) return const [];
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(UserCostumeModel.fromJson)
        .toList();
  }

  Future<UserCostumeModel> fetchCostumeById(String id) async {
    final res = await _api.get('/user/costumes', queryParameters: {'id': id});
    final raw = res['data'];
    if (raw is Map<String, dynamic>) {
      return UserCostumeModel.fromJson(raw);
    }
    throw Exception('Data kostum tidak ditemukan.');
  }

  Future<List<UserEventModel>> fetchEvents() async {
    final res = await _api.get('/user/events');
    final rawList = res['data'];
    if (rawList is! List) return const [];
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(UserEventModel.fromJson)
        .toList();
  }

  Future<List<UserReviewModel>> fetchReviews(String targetId) async {
    final res = await _api.get(
      '/user/reviews',
      queryParameters: {'targetId': targetId},
    );
    final rawList = res['data'];
    if (rawList is! List) return const [];
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(UserReviewModel.fromJson)
        .toList();
  }

  Future<UserReviewModel> submitReview({
    required String targetId,
    required String targetType,
    required int rating,
    required String comment,
  }) async {
    final res = await _api.post(
      '/user/reviews',
      data: {
        'targetId': targetId,
        'targetType': targetType,
        'rating': rating,
        'comment': comment.trim(),
        'verified': true,
      },
    );
    final raw = res['data'];
    if (raw is Map<String, dynamic>) {
      return UserReviewModel.fromJson(raw);
    }
    throw Exception('Gagal menyimpan ulasan.');
  }

  Future<List<WishlistItemModel>> fetchWishlist() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) {
      return const [];
    }
    final res = await _api.get('/user/wishlist');
    final rawList = res['data'];
    if (rawList is! List) return const [];
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map(WishlistItemModel.fromJson)
        .toList();
    await _storage.saveWishlistIds(items.map((e) => e.targetId).toList());
    return items;
  }

  Future<List<WishlistItemModel>> addToWishlist({
    required String targetId,
    required String targetType,
  }) async {
    final res = await _api.post(
      '/user/wishlist',
      data: {'targetId': targetId, 'targetType': targetType},
    );
    final rawList = res['data'];
    final items = rawList is List
        ? rawList
            .whereType<Map<String, dynamic>>()
            .map(WishlistItemModel.fromJson)
            .toList()
        : const <WishlistItemModel>[];
    await _storage.saveWishlistIds(items.map((e) => e.targetId).toList());
    return items;
  }

  Future<List<WishlistItemModel>> removeFromWishlist(String targetId) async {
    final res = await _api.delete(
      '/user/wishlist',
      queryParameters: {'targetId': targetId},
    );
    final rawList = res['data'];
    final items = rawList is List
        ? rawList
            .whereType<Map<String, dynamic>>()
            .map(WishlistItemModel.fromJson)
            .toList()
        : const <WishlistItemModel>[];
    await _storage.saveWishlistIds(items.map((e) => e.targetId).toList());
    return items;
  }

  Future<void> saveCostumeBookingDraft(BookingCartItemModel selection) async {
    final existing = await _storage.getBookingDraftJson();
    final rawCostumes = (existing?['costumes'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(BookingCartItemModel.fromJson)
            .toList() ??
        <BookingCartItemModel>[];

    final idx = rawCostumes.indexWhere(
      (c) => c.id == selection.id && c.size == selection.size,
    );
    if (idx >= 0) {
      rawCostumes[idx] = selection;
    } else {
      rawCostumes.add(selection);
    }

    await _storage.saveBookingDraftJson({
      ...?existing,
      'costumes': rawCostumes.map((e) => e.toJson()).toList(),
    });
  }
}
