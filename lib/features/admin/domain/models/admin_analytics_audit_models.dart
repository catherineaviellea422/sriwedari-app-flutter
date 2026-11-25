import 'package:equatable/equatable.dart';
import 'admin_catalog_models.dart';

class AuditLogModel extends Equatable {
  const AuditLogModel({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.actorName,
    required this.actorRole,
    required this.details,
    required this.ipAddress,
    this.severity = 'info',
  });

  final String id;
  final String timestamp;
  final String action;
  final String actorName;
  final String actorRole;
  final String details;
  final String ipAddress;
  final String severity;

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: (json['id'] ?? '').toString(),
      timestamp: (json['timestamp'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      actorName: (json['actorName'] ?? '').toString(),
      actorRole: (json['actorRole'] ?? '').toString(),
      details: (json['details'] ?? '').toString(),
      ipAddress: (json['ipAddress'] ?? '').toString(),
      severity: (json['severity'] ?? 'info').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'action': action,
      'actorName': actorName,
      'actorRole': actorRole,
      'details': details,
      'ipAddress': ipAddress,
      'severity': severity,
    };
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        action,
        actorName,
        actorRole,
        details,
        ipAddress,
        severity,
      ];
}

class AnalyticsSnapshotModel extends Equatable {
  const AnalyticsSnapshotModel({
    required this.date,
    required this.visitors,
    required this.revenue,
    required this.ordersCount,
    required this.ticketsCount,
  });

  final String date;
  final int visitors;
  final int revenue;
  final int ordersCount;
  final int ticketsCount;

  factory AnalyticsSnapshotModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsSnapshotModel(
      date: (json['date'] ?? '').toString(),
      visitors: (json['visitors'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toInt() ?? 0,
      ordersCount: (json['ordersCount'] as num?)?.toInt() ?? 0,
      ticketsCount: (json['ticketsCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'visitors': visitors,
      'revenue': revenue,
      'ordersCount': ordersCount,
      'ticketsCount': ticketsCount,
    };
  }

  @override
  List<Object?> get props => [date, visitors, revenue, ordersCount, ticketsCount];
}

class PaymentChannelBreakdown extends Equatable {
  const PaymentChannelBreakdown({
    this.qris = 0,
    this.va = 0,
    this.tunai = 0,
  });

  final int qris;
  final int va;
  final int tunai;

  factory PaymentChannelBreakdown.fromJson(Map<String, dynamic> json) {
    return PaymentChannelBreakdown(
      qris: (json['QRIS'] as num?)?.toInt() ?? 0,
      va: (json['VA'] as num?)?.toInt() ?? 0,
      tunai: (json['Tunai'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'QRIS': qris,
      'VA': va,
      'Tunai': tunai,
    };
  }

  @override
  List<Object?> get props => [qris, va, tunai];
}

class AnalyticsSummaryModel extends Equatable {
  const AnalyticsSummaryModel({
    this.totalRevenue = 0,
    this.revenueRental = 0,
    this.revenueTickets = 0,
    this.escrowDeposit = 0,
    this.qcDeductions = 0,
    this.paymentChannels = const PaymentChannelBreakdown(),
    this.totalOrders = 0,
    this.activeOrders = 0,
    this.completedOrders = 0,
    this.totalUsers = 0,
    this.totalTicketsSold = 0,
    this.gateCheckinCount = 0,
    this.occupancyRate = 0,
    this.totalCostumes = 0,
    this.totalGalleries = 0,
    this.totalEvents = 0,
    this.topGalleries = const [],
    this.recentActivities = const [],
    this.weeklyVisitors = const [],
  });

  final int totalRevenue;
  final int revenueRental;
  final int revenueTickets;
  final int escrowDeposit;
  final int qcDeductions;
  final PaymentChannelBreakdown paymentChannels;
  final int totalOrders;
  final int activeOrders;
  final int completedOrders;
  final int totalUsers;
  final int totalTicketsSold;
  final int gateCheckinCount;
  final int occupancyRate;
  final int totalCostumes;
  final int totalGalleries;
  final int totalEvents;
  final List<AdminGalleryModel> topGalleries;
  final List<AuditLogModel> recentActivities;
  final List<AnalyticsSnapshotModel> weeklyVisitors;

  factory AnalyticsSummaryModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummaryModel(
      totalRevenue: (json['totalRevenue'] as num?)?.toInt() ?? 0,
      revenueRental: (json['revenueRental'] as num?)?.toInt() ?? 0,
      revenueTickets: (json['revenueTickets'] as num?)?.toInt() ?? 0,
      escrowDeposit: (json['escrowDeposit'] as num?)?.toInt() ?? 0,
      qcDeductions: (json['qcDeductions'] as num?)?.toInt() ?? 0,
      paymentChannels: json['paymentChannels'] is Map<String, dynamic>
          ? PaymentChannelBreakdown.fromJson(
              json['paymentChannels'] as Map<String, dynamic>,
            )
          : const PaymentChannelBreakdown(),
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      activeOrders: (json['activeOrders'] as num?)?.toInt() ?? 0,
      completedOrders: (json['completedOrders'] as num?)?.toInt() ?? 0,
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalTicketsSold: (json['totalTicketsSold'] as num?)?.toInt() ?? 0,
      gateCheckinCount: (json['gateCheckinCount'] as num?)?.toInt() ?? 0,
      occupancyRate: (json['occupancyRate'] as num?)?.toInt() ?? 0,
      totalCostumes: (json['totalCostumes'] as num?)?.toInt() ?? 0,
      totalGalleries: (json['totalGalleries'] as num?)?.toInt() ?? 0,
      totalEvents: (json['totalEvents'] as num?)?.toInt() ?? 0,
      topGalleries: (json['topGalleries'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(AdminGalleryModel.fromJson)
              .toList() ??
          const [],
      recentActivities: (json['recentActivities'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(AuditLogModel.fromJson)
              .toList() ??
          const [],
      weeklyVisitors: (json['weeklyVisitors'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(AnalyticsSnapshotModel.fromJson)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRevenue': totalRevenue,
      'revenueRental': revenueRental,
      'revenueTickets': revenueTickets,
      'escrowDeposit': escrowDeposit,
      'qcDeductions': qcDeductions,
      'paymentChannels': paymentChannels.toJson(),
      'totalOrders': totalOrders,
      'activeOrders': activeOrders,
      'completedOrders': completedOrders,
      'totalUsers': totalUsers,
      'totalTicketsSold': totalTicketsSold,
      'gateCheckinCount': gateCheckinCount,
      'occupancyRate': occupancyRate,
      'totalCostumes': totalCostumes,
      'totalGalleries': totalGalleries,
      'totalEvents': totalEvents,
      'topGalleries': topGalleries.map((e) => e.toJson()).toList(),
      'recentActivities': recentActivities.map((e) => e.toJson()).toList(),
      'weeklyVisitors': weeklyVisitors.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        totalRevenue,
        revenueRental,
        revenueTickets,
        escrowDeposit,
        qcDeductions,
        paymentChannels,
        totalOrders,
        activeOrders,
        completedOrders,
        totalUsers,
        totalTicketsSold,
        gateCheckinCount,
        occupancyRate,
        totalCostumes,
        totalGalleries,
        totalEvents,
        topGalleries,
        recentActivities,
        weeklyVisitors,
      ];
}

class SystemSettingsModel extends Equatable {
  const SystemSettingsModel({
    required this.galleryName,
    required this.tagline,
    required this.openHours,
    required this.location,
    required this.phone,
    required this.email,
    required this.depositFee,
    required this.terms,
    this.notifications = true,
    this.holdDurationMinutes = 1440,
    this.refundWindowDays = 3,
    this.lowStockThreshold = 2,
    this.whatsappAdminNumber = '6281234567890',
  });

  final String galleryName;
  final String tagline;
  final String openHours;
  final String location;
  final String phone;
  final String email;
  final int depositFee;
  final String terms;
  final bool notifications;
  final int holdDurationMinutes;
  final int refundWindowDays;
  final int lowStockThreshold;
  final String whatsappAdminNumber;

  factory SystemSettingsModel.fromJson(Map<String, dynamic> json) {
    return SystemSettingsModel(
      galleryName: (json['galleryName'] ?? 'Galeri Pusaka Seni Sriwedari').toString(),
      tagline: (json['tagline'] ?? '').toString(),
      openHours: (json['openHours'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      depositFee: (json['depositFee'] as num?)?.toInt() ?? 100000,
      terms: (json['terms'] ?? '').toString(),
      notifications: json['notifications'] != false,
      holdDurationMinutes: (json['holdDurationMinutes'] as num?)?.toInt() ?? 1440,
      refundWindowDays: (json['refundWindowDays'] as num?)?.toInt() ?? 3,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 2,
      whatsappAdminNumber: (json['whatsappAdminNumber'] ?? '6281234567890').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'galleryName': galleryName,
      'tagline': tagline,
      'openHours': openHours,
      'location': location,
      'phone': phone,
      'email': email,
      'depositFee': depositFee,
      'terms': terms,
      'notifications': notifications,
      'holdDurationMinutes': holdDurationMinutes,
      'refundWindowDays': refundWindowDays,
      'lowStockThreshold': lowStockThreshold,
      'whatsappAdminNumber': whatsappAdminNumber,
    };
  }

  @override
  List<Object?> get props => [
        galleryName,
        tagline,
        openHours,
        location,
        phone,
        email,
        depositFee,
        terms,
        notifications,
        holdDurationMinutes,
        refundWindowDays,
        lowStockThreshold,
        whatsappAdminNumber,
      ];
}
