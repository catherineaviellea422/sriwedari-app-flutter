import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/user_catalog_repository.dart';
import '../../domain/models/user_models.dart';

final userCatalogRepositoryProvider = Provider<UserCatalogRepository>((ref) {
  return UserCatalogRepository(
    userApiClient: ref.watch(userApiClientProvider),
    userStorage: ref.watch(userLocalStorageProvider),
  );
});

class UserGalleriesNotifier extends AsyncNotifier<List<UserGalleryModel>> {
  @override
  Future<List<UserGalleryModel>> build() async {
    return ref.watch(userCatalogRepositoryProvider).fetchGalleries();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(userCatalogRepositoryProvider).fetchGalleries(),
    );
  }

  Future<void> toggleLike(String galleryId) async {
    final current = state.value;
    if (current == null) return;

    final idx = current.indexWhere((g) => g.id == galleryId);
    if (idx < 0) return;

    final prevItem = current[idx];
    final optimisticNext = prevItem.copyWith(
      isLiked: !prevItem.isLiked,
      likes: (prevItem.likes + (prevItem.isLiked ? -1 : 1)).clamp(0, 999999),
    );
    final nextList = [...current]..[idx] = optimisticNext;
    state = AsyncData(nextList);

    try {
      final serverRes = await ref
          .read(userCatalogRepositoryProvider)
          .toggleGalleryLike(galleryId);
      final syncedList = [...(state.value ?? nextList)];
      final syncedIdx = syncedList.indexWhere((g) => g.id == galleryId);
      if (syncedIdx >= 0) {
        syncedList[syncedIdx] = syncedList[syncedIdx].copyWith(
          isLiked: serverRes.isLiked,
          likes: serverRes.likes,
        );
        state = AsyncData(syncedList);
      }
    } catch (_) {
      // Rollback jika gagal
      final rollback = [...(state.value ?? nextList)];
      final rollbackIdx = rollback.indexWhere((g) => g.id == galleryId);
      if (rollbackIdx >= 0) {
        rollback[rollbackIdx] = prevItem;
        state = AsyncData(rollback);
      }
      rethrow;
    }
  }
}

final userGalleriesProvider =
    AsyncNotifierProvider<UserGalleriesNotifier, List<UserGalleryModel>>(
  UserGalleriesNotifier.new,
);

final userCategoriesProvider = FutureProvider<List<UserCategoryModel>>((ref) {
  return ref.watch(userCatalogRepositoryProvider).fetchCategories();
});

class UserCostumesNotifier extends AsyncNotifier<List<UserCostumeModel>> {
  @override
  Future<List<UserCostumeModel>> build() async {
    return ref.watch(userCatalogRepositoryProvider).fetchCostumes();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(userCatalogRepositoryProvider).fetchCostumes(),
    );
  }
}

final userCostumesProvider =
    AsyncNotifierProvider<UserCostumesNotifier, List<UserCostumeModel>>(
  UserCostumesNotifier.new,
);

final userEventsProvider = FutureProvider<List<UserEventModel>>((ref) {
  return ref.watch(userCatalogRepositoryProvider).fetchEvents();
});

final targetReviewsProvider =
    FutureProvider.family<List<UserReviewModel>, String>((ref, targetId) {
  return ref.watch(userCatalogRepositoryProvider).fetchReviews(targetId);
});

class UserWishlistNotifier extends AsyncNotifier<List<WishlistItemModel>> {
  @override
  Future<List<WishlistItemModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isUser) {
      return const [];
    }
    return ref.watch(userCatalogRepositoryProvider).fetchWishlist();
  }

  bool containsTarget(String targetId) {
    final items = state.value ?? const [];
    return items.any((w) => w.targetId == targetId);
  }

  Future<bool> toggleWishlist({
    required String targetId,
    required String targetType,
  }) async {
    final auth = ref.read(authProvider);
    if (!auth.isUser) {
      return false;
    }

    final repo = ref.read(userCatalogRepositoryProvider);
    final alreadySaved = containsTarget(targetId);
    final prevList = state.value ?? const <WishlistItemModel>[];

    if (alreadySaved) {
      state = AsyncData(
        prevList.where((w) => w.targetId != targetId).toList(),
      );
      try {
        final updated = await repo.removeFromWishlist(targetId);
        state = AsyncData(updated);
      } catch (_) {
        state = AsyncData(prevList);
        rethrow;
      }
    } else {
      final optimisticItem = WishlistItemModel(
        id: 'wl-temp-$targetId',
        userId: auth.userAccount?.id ?? '',
        targetId: targetId,
        targetType: targetType,
        createdAt: DateTime.now().toIso8601String(),
      );
      state = AsyncData([optimisticItem, ...prevList]);
      try {
        final updated = await repo.addToWishlist(
          targetId: targetId,
          targetType: targetType,
        );
        state = AsyncData(updated);
      } catch (_) {
        state = AsyncData(prevList);
        rethrow;
      }
    }
    return true;
  }
}

final userWishlistProvider =
    AsyncNotifierProvider<UserWishlistNotifier, List<WishlistItemModel>>(
  UserWishlistNotifier.new,
);
