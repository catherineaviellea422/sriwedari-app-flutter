import 'package:flutter_test/flutter_test.dart';
import 'package:sriwedari_app/features/admin/domain/models/admin_models.dart';
import 'package:sriwedari_app/features/user/domain/models/user_models.dart';

void main() {
  group('User Models JSON Serialization (sriwedari-user-db)', () {
    test('UserAccountModel, UserGalleryModel, UserCategoryModel, UserCostumeModel round-trip', () {
      final userJson = {
        'id': 'usr-user-1',
        'name': 'Oliv Satoro',
        'email': 'oliv@example.com',
        'phone': '081234567890',
        'role': 'user',
        'status': 'active',
        'points': 420,
        'registeredAt': '2025-06-15',
      };
      final user = UserAccountModel.fromJson(userJson);
      expect(user.id, 'usr-user-1');
      expect(user.points, 420);
      expect(UserAccountModel.fromJson(user.toJson()), user);

      final galleryJson = {
        'id': 'gal-1',
        'title': 'Tari Topeng Malangan',
        'category': 'tari-tradisional',
        'categoryName': 'Tari Tradisional',
        'type': 'foto',
        'date': '2025-01-10',
        'description': 'Seni pertunjukan wayang topeng khas Jawa Timur.',
        'image': '/images/tari-topeng-malangan.png',
        'views': 1420,
        'likes': 358,
        'isLiked': false,
        'origin': 'Malang, Jawa Timur',
        'costumeId': 'costume-topeng',
      };
      final gallery = UserGalleryModel.fromJson(galleryJson);
      expect(gallery.costumeId, 'costume-topeng');
      expect(gallery.isVideo, isFalse);
      expect(UserGalleryModel.fromJson(gallery.toJson()), gallery);

      final categoryJson = {
        'id': 'cat-1',
        'name': 'Tari Tradisional',
        'icon': 'theater_comedy',
        'description': 'Karya tari pakem warisan keraton',
        'count': 7,
      };
      final category = UserCategoryModel.fromJson(categoryJson);
      expect(UserCategoryModel.fromJson(category.toJson()), category);

      final costumeJson = {
        'id': 'costume-topeng',
        'name': 'Busana Ksatria Topeng Malangan',
        'category': 'Jawa Timuran',
        'price': 250000,
        'rating': 4.9,
        'reviewCount': 38,
        'stock': 4,
        'sizes': ['S', 'M', 'L', 'XL'],
        'sizeStocks': {'S': 1, 'M': 2, 'L': 1, 'XL': 0},
        'image': '/images/tari-topeng-malangan.png',
        'description': 'Satu set lengkap topeng dan kain parang.',
        'origin': 'Malang, Jawa Timur',
      };
      final costume = UserCostumeModel.fromJson(costumeJson);
      expect(costume.isAvailable, isTrue);
      expect(costume.sizeStocks['M'], 2);
      expect(UserCostumeModel.fromJson(costume.toJson()), costume);
    });

    test('UserOrderModel, UserEventModel, UserTicketModel, WishlistItemModel, UserCouponModel round-trip', () {
      final orderJson = {
        'id': 'ORD-2026-8812',
        'userName': 'Oliv Satoro',
        'userPhone': '081234567890',
        'userEmail': 'oliv@example.com',
        'costumeId': 'costume-gandrung',
        'costumeName': 'Kostum Lengkap Gandrung Omprok',
        'costumes': [
          {
            'id': 'costume-gandrung',
            'name': 'Kostum Lengkap Gandrung Omprok',
            'price': 300000,
            'days': 3,
            'size': 'M',
          }
        ],
        'startDate': '2026-10-30',
        'duration': 3,
        'totalPrice': 1000000,
        'depositFee': 100000,
        'discountAmount': 0,
        'status': 'Menunggu',
        'paymentMethod': 'QRIS',
        'paymentProof': '/images/tari-topeng-malangan.png',
        'createdAt': '2026-10-24 14:30',
      };
      final order = UserOrderModel.fromJson(orderJson);
      expect(order.costumes.single.subtotal, 900000);
      expect(UserOrderModel.fromJson(order.toJson()), order);

      final eventJson = {
        'id': 'evt-1',
        'title': 'Pagelaran Wayang Orang Sriwedari',
        'date': '2026-10-31',
        'time': '20:00 WIB',
        'location': 'GWO Sriwedari',
        'price': 50000,
        'quota': 200,
        'booked': 142,
        'image': '/images/tari-jawa-dramatic-stage.png',
        'description': 'Lakon Ramayana Tambak.',
        'zonePrices': {'VIP': 50000, 'REGULER': 35000, 'BALKON': 25000},
      };
      final event = UserEventModel.fromJson(eventJson);
      expect(event.remainingQuota, 58);
      expect(event.zonePrices?.priceForZone('VIP'), 50000);
      expect(UserEventModel.fromJson(event.toJson()), event);

      final ticketJson = {
        'id': 'TCK-2026-001',
        'eventId': 'evt-1',
        'eventTitle': 'Pagelaran Wayang Orang Sriwedari',
        'userName': 'Oliv Satoro',
        'userPhone': '081234567890',
        'quantity': 2,
        'seats': ['A-03', 'A-04'],
        'zone': 'VIP',
        'totalPrice': 100000,
        'status': 'Aktif',
        'bookingCode': 'SWD-RAMA-9921',
        'createdAt': '2026-10-24 16:00',
      };
      final ticket = UserTicketModel.fromJson(ticketJson);
      expect(UserTicketModel.fromJson(ticket.toJson()), ticket);

      final wishlist = WishlistItemModel.fromJson({
        'id': 'wl-seed-1',
        'userId': 'usr-user-1',
        'targetId': 'gal-3',
        'targetType': 'gallery',
        'createdAt': '2026-10-24 10:00:00',
      });
      expect(WishlistItemModel.fromJson(wishlist.toJson()), wishlist);

      final coupon = UserCouponModel.fromJson({
        'id': 'coup-1',
        'code': 'SRIWEDARI10',
        'type': 'PERCENTAGE',
        'value': 10,
        'minOrder': 200000,
        'maxUses': 100,
        'usedCount': 23,
        'isActive': true,
        'expiresAt': '2026-12-31',
      });
      expect(UserCouponModel.fromJson(coupon.toJson()), coupon);
    });
  });

  group('Admin Models JSON Serialization (sriwedari-admin-db)', () {
    test('AdminAccountModel, AdminOrderQcModel, StockMovementModel, AuditLogModel, AnalyticsSummaryModel', () {
      final admin = AdminAccountModel.fromJson({
        'id': 'usr-admin-1',
        'name': 'Kanjeng Raden Mas Kurator',
        'email': 'admin@galerisriwedari.id',
        'phone': '081122334455',
        'role': 'admin',
        'status': 'active',
        'points': 1500,
        'registeredAt': '2024-01-01',
      });
      expect(admin.isAdmin, isTrue);
      expect(AdminAccountModel.fromJson(admin.toJson()), admin);

      final qcOrder = AdminOrderQcModel.fromJson({
        'id': 'ORD-2026-7734',
        'userName': 'Raden Mas Haryo',
        'userPhone': '081399887766',
        'userEmail': 'haryo@keratonsolo.id',
        'costumeId': 'costume-bedhaya',
        'costumeName': 'Busana Dodot Ageng',
        'startDate': '2026-10-28',
        'duration': 2,
        'totalPrice': 1000000,
        'depositFee': 100000,
        'status': 'Dikonfirmasi',
        'paymentMethod': 'VA',
        'createdAt': '2026-10-23 09:15',
      });
      expect(qcOrder.computeRefundForGrade('Grade A'), 100000);
      expect(qcOrder.computeRefundForGrade('Grade B'), 75000);
      expect(qcOrder.computeRefundForGrade('Grade C'), 50000);
      expect(qcOrder.computeRefundForGrade('Grade D'), 0);
      expect(AdminOrderQcModel.fromJson(qcOrder.toJson()), qcOrder);

      final movement = StockMovementModel.fromJson({
        'id': 'sm-1',
        'costumeId': 'costume-gandrung',
        'costumeName': 'Kostum Gandrung',
        'size': 'M',
        'delta': -1,
        'stockAfter': 2,
        'reason': 'disewa',
        'actorName': 'Oliv Satoro',
        'orderId': 'ORD-2026-8812',
        'createdAt': '2026-10-24 14:30:00',
      });
      expect(StockMovementModel.fromJson(movement.toJson()), movement);

      final analytics = AnalyticsSummaryModel.fromJson({
        'totalRevenue': 1100000,
        'revenueRental': 1000000,
        'revenueTickets': 100000,
        'escrowDeposit': 100000,
        'qcDeductions': 25000,
        'paymentChannels': {'QRIS': 500000, 'VA': 500000, 'Tunai': 100000},
        'totalOrders': 2,
        'activeOrders': 2,
        'completedOrders': 0,
        'totalUsers': 3,
        'totalTicketsSold': 2,
        'gateCheckinCount': 1,
        'occupancyRate': 69,
        'totalCostumes': 6,
        'totalGalleries': 9,
        'totalEvents': 2,
        'topGalleries': [
          {
            'id': 'gal-9',
            'title': 'Tari Kecak',
            'category': 'tari-tradisional',
            'categoryName': 'Tari Tradisional',
            'type': 'foto',
            'date': '2024-12-15',
            'description': 'Kolosal',
            'image': '/images/tari-kecak.png',
            'views': 5200,
            'likes': 1680,
            'origin': 'Bali',
          }
        ],
        'recentActivities': [
          {
            'id': 'aud-1',
            'timestamp': '2026-10-25 09:30:12',
            'action': 'VERIFY_PAYMENT',
            'actorName': 'Kurator',
            'actorRole': 'Admin',
            'details': 'Verifikasi',
            'ipAddress': '127.0.0.1',
            'severity': 'info',
          }
        ],
        'weeklyVisitors': [
          {
            'date': '2026-10-25',
            'visitors': 210,
            'revenue': 1500000,
            'ordersCount': 3,
            'ticketsCount': 12,
          }
        ],
      });
      expect(analytics.paymentChannels.qris, 500000);
      expect(analytics.topGalleries.single.id, 'gal-9');
      expect(analytics.weeklyVisitors.single.visitors, 210);
      expect(AnalyticsSummaryModel.fromJson(analytics.toJson()), analytics);

      final settings = SystemSettingsModel.fromJson({
        'galleryName': 'Galeri Sriwedari',
        'tagline': 'Lumbung Pelestarian',
        'openHours': '08.00 - 22.00',
        'location': 'Surakarta',
        'phone': '0812',
        'email': 'info@galerisriwedari.id',
        'depositFee': 100000,
        'terms': 'Syarat berlaku',
        'notifications': true,
      });
      expect(SystemSettingsModel.fromJson(settings.toJson()), settings);
    });
  });
}
