import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/user_transactions_repository.dart';
import '../../domain/models/user_models.dart';

final userTransactionsRepositoryProvider =
    Provider<UserTransactionsRepository>((ref) {
  return UserTransactionsRepository(
    userApiClient: ref.watch(userApiClientProvider),
    userStorage: ref.watch(userLocalStorageProvider),
  );
});

class UserOrdersNotifier extends AsyncNotifier<List<UserOrderModel>> {
  @override
  Future<List<UserOrderModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) return const [];
    return ref.watch(userTransactionsRepositoryProvider).fetchMyOrders();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(userTransactionsRepositoryProvider).fetchMyOrders(),
    );
  }
}

final userOrdersProvider =
    AsyncNotifierProvider<UserOrdersNotifier, List<UserOrderModel>>(
  UserOrdersNotifier.new,
);

class UserTicketsNotifier extends AsyncNotifier<List<UserTicketModel>> {
  @override
  Future<List<UserTicketModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) return const [];
    return ref.watch(userTransactionsRepositoryProvider).fetchMyTickets();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(userTransactionsRepositoryProvider).fetchMyTickets(),
    );
  }
}

final userTicketsProvider =
    AsyncNotifierProvider<UserTicketsNotifier, List<UserTicketModel>>(
  UserTicketsNotifier.new,
);

final bookedSeatsProvider =
    FutureProvider.family<List<String>, String>((ref, eventId) {
  return ref
      .watch(userTransactionsRepositoryProvider)
      .fetchBookedSeats(eventId);
});

final publicSettingsProvider = FutureProvider<PublicSettingsModel>((ref) {
  return ref.watch(userTransactionsRepositoryProvider).fetchPublicSettings();
});
