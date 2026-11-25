import 'domain_exports.dart';

class BookingCostCalculator {
  const BookingCostCalculator._();

  static int calculateRentalSubtotal(List<BookingCartItemModel> items) {
    return items.fold<int>(0, (sum, item) => sum + item.subtotal);
  }

  static int calculateCouponDiscount({
    required int subtotal,
    required String couponType,
    required int couponValue,
    int minOrder = 0,
  }) {
    if (subtotal <= 0 || subtotal < minOrder) return 0;
    final rawDiscount = couponType.toUpperCase() == 'PERCENTAGE'
        ? ((subtotal * couponValue) / 100).round()
        : couponValue;
    return rawDiscount.clamp(0, subtotal);
  }

  static int calculateGrandTotal({
    required int subtotal,
    required int discountAmount,
    int depositFee = 100000,
  }) {
    final discountedRental = (subtotal - discountAmount).clamp(0, subtotal);
    return discountedRental + (subtotal > 0 ? depositFee : 0);
  }
}

class TheaterZoneConfig {
  const TheaterZoneConfig({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.rows,
    required this.defaultPrice,
  });

  final String id;
  final String label;
  final String subtitle;
  final List<String> rows;
  final int defaultPrice;
}

class TheaterSeatMapHelper {
  const TheaterSeatMapHelper._();

  static const int seatsPerRow = 8;

  static const List<TheaterZoneConfig> zones = [
    TheaterZoneConfig(
      id: 'VIP',
      label: 'VIP Pendopo',
      subtitle: 'Baris A–B • Meja jati depan panggung & teh tubruk',
      rows: ['A', 'B'],
      defaultPrice: 50000,
    ),
    TheaterZoneConfig(
      id: 'REGULER',
      label: 'Reguler Tengah',
      subtitle: 'Baris C–D • Pandangan langsung panggung utama',
      rows: ['C', 'D'],
      defaultPrice: 35000,
    ),
    TheaterZoneConfig(
      id: 'BALKON',
      label: 'Balkon Samping',
      subtitle: 'Baris E–F • Pandangan atas orkestra gamelan',
      rows: ['E', 'F'],
      defaultPrice: 25000,
    ),
  ];

  static List<String> seatsForRow(String rowLabel) {
    return List.generate(
      seatsPerRow,
      (i) => '$rowLabel-${(i + 1).toString().padLeft(2, '0')}',
    );
  }

  static ({bool valid, String? error}) validateSeatSelection({
    required List<String> selectedSeats,
    required Set<String> bookedSeats,
    int maxSeats = 5,
  }) {
    if (selectedSeats.isEmpty) {
      return (
        valid: false,
        error: 'Silakan pilih minimal satu nomor kursi pada denah pementasan.',
      );
    }
    if (selectedSeats.length > maxSeats) {
      return (
        valid: false,
        error: 'Maksimal pemesanan $maxSeats kursi per transaksi.',
      );
    }
    final conflicts = selectedSeats.where(bookedSeats.contains).toList();
    if (conflicts.isNotEmpty) {
      return (
        valid: false,
        error:
            'Kursi [${conflicts.join(', ')}] sudah dipesan penonton lain. Silakan pilih kursi lain.',
      );
    }
    return (valid: true, error: null);
  }
}
