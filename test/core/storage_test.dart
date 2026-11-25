import 'package:flutter_test/flutter_test.dart';
import 'package:sriwedari_app/core/storage/admin_local_storage.dart';
import 'package:sriwedari_app/core/storage/storage_backend.dart';
import 'package:sriwedari_app/core/storage/user_local_storage.dart';

void main() {
  group('Dual Local Storage Isolation (User vs Admin)', () {
    late InMemoryKeyValueStore sharedKv;
    late InMemorySecureStore sharedSecure;
    late UserLocalStorage userStorage;
    late AdminLocalStorage adminStorage;

    setUp(() {
      sharedKv = InMemoryKeyValueStore();
      sharedSecure = InMemorySecureStore();
      userStorage = UserLocalStorage(kvStore: sharedKv, secureStore: sharedSecure);
      adminStorage = AdminLocalStorage(kvStore: sharedKv, secureStore: sharedSecure);
    });

    test('token, profile, dan data user terisolasi penuh dari admin', () async {
      await userStorage.saveToken('user-jwt-token-123');
      await userStorage.saveUserProfileJson({
        'id': 'usr-user-1',
        'name': 'Oliv Satoro',
        'role': 'user',
      });
      await userStorage.saveWishlistIds(['gal-1', 'costume-gandrung']);
      await userStorage.saveBookingDraftJson({'costumeId': 'costume-gandrung', 'days': 3});
      await userStorage.saveOfflineTicketsJson([
        {'bookingCode': 'SWD-RAMA-9921', 'zone': 'VIP'},
      ]);

      await adminStorage.saveToken('admin-jwt-token-999');
      await adminStorage.saveAdminProfileJson({
        'id': 'usr-admin-1',
        'name': 'Kanjeng Raden Mas Kurator',
        'role': 'admin',
      });
      await adminStorage.saveAnalyticsCacheJson({'totalRevenue': 2100000});
      await adminStorage.setOrderFilterStatus('Menunggu');

      expect(await userStorage.getToken(), 'user-jwt-token-123');
      expect(await adminStorage.getToken(), 'admin-jwt-token-999');
      expect((await userStorage.getUserProfileJson())?['role'], 'user');
      expect((await adminStorage.getAdminProfileJson())?['role'], 'admin');
      expect(await userStorage.getWishlistIds(), ['gal-1', 'costume-gandrung']);
      expect((await adminStorage.getAnalyticsCacheJson())?['totalRevenue'], 2100000);
    });

    test('clearAll pada UserLocalStorage tidak menghapus data AdminLocalStorage', () async {
      await userStorage.saveToken('user-token');
      await userStorage.saveWishlistIds(['gal-3']);
      await adminStorage.saveToken('admin-token');
      await adminStorage.saveAdminProfileJson({'id': 'usr-admin-1', 'role': 'admin'});
      await adminStorage.setSelectedPosEventId('evt-1');

      await userStorage.clearAll();

      expect(await userStorage.getToken(), isNull);
      expect(await userStorage.getWishlistIds(), isEmpty);

      expect(await adminStorage.getToken(), 'admin-token');
      expect((await adminStorage.getAdminProfileJson())?['id'], 'usr-admin-1');
      expect(await adminStorage.getSelectedPosEventId(), 'evt-1');
    });

    test('clearAll pada AdminLocalStorage tidak menghapus data UserLocalStorage', () async {
      await userStorage.saveToken('user-token');
      await userStorage.saveUserProfileJson({'id': 'usr-user-1', 'name': 'Oliv'});
      await userStorage.saveOfflineTicketsJson([
        {'bookingCode': 'SWD-001'},
      ]);
      await adminStorage.saveToken('admin-token');
      await adminStorage.appendGateScanHistoryJson({'code': 'SWD-001', 'valid': true});

      await adminStorage.clearAll();

      expect(await adminStorage.getToken(), isNull);
      expect(await adminStorage.getGateScanHistoryJson(), isEmpty);

      expect(await userStorage.getToken(), 'user-token');
      expect((await userStorage.getUserProfileJson())?['name'], 'Oliv');
      expect(await userStorage.getOfflineTicketsJson(), hasLength(1));
    });

    test('recent searches dan wishlist tidak duplikat dan terbatas 8 item', () async {
      for (var i = 1; i <= 10; i++) {
        await userStorage.addRecentSearch('Tari $i');
      }
      await userStorage.addRecentSearch('Tari 10');
      final recent = await userStorage.getRecentSearches();
      expect(recent.length, 8);
      expect(recent.first, 'Tari 10');
    });
  });
}
