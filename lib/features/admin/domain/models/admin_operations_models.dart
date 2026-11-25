import 'package:equatable/equatable.dart';
import '../../../user/domain/models/user_event_ticket_model.dart';
import '../../../user/domain/models/user_order_model.dart';

class AdminOrderQcModel extends Equatable {
  const AdminOrderQcModel({
    required this.id,
    this.userId,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    required this.costumeId,
    required this.costumeName,
    this.costumes = const [],
    required this.startDate,
    required this.duration,
    required this.totalPrice,
    required this.depositFee,
    this.discountAmount = 0,
    this.couponCode,
    required this.status,
    required this.paymentMethod,
    this.paymentProof,
    this.qcStatus,
    this.refundAmount,
    this.deductionNote,
    required this.createdAt,
    this.holdExpiresAt,
    this.completedAt,
    this.refundStatus,
    this.cancelReason,
  });

  final String id;
  final String? userId;
  final String userName;
  final String userPhone;
  final String userEmail;
  final String costumeId;
  final String costumeName;
  final List<BookingCartItemModel> costumes;
  final String startDate;
  final int duration;
  final int totalPrice;
  final int depositFee;
  final int discountAmount;
  final String? couponCode;
  final String status;
  final String paymentMethod;
  final String? paymentProof;
  final String? qcStatus;
  final int? refundAmount;
  final String? deductionNote;
  final String createdAt;
  final String? holdExpiresAt;
  final String? completedAt;
  final String? refundStatus;
  final String? cancelReason;

  static int deductionForQcGrade(String grade) {
    return switch (grade) {
      'Grade A' => 0,
      'Grade B' => 25000,
      'Grade C' => 50000,
      'Grade D' => 100000,
      _ => 0,
    };
  }

  int computeRefundForGrade(String grade) {
    final deduction = deductionForQcGrade(grade);
    return (depositFee - deduction).clamp(0, depositFee);
  }

  factory AdminOrderQcModel.fromJson(Map<String, dynamic> json) {
    final items = (json['costumes'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(BookingCartItemModel.fromJson)
            .toList() ??
        const <BookingCartItemModel>[];

    return AdminOrderQcModel(
      id: (json['id'] ?? '').toString(),
      userId: json['userId']?.toString(),
      userName: (json['userName'] ?? '').toString(),
      userPhone: (json['userPhone'] ?? '').toString(),
      userEmail: (json['userEmail'] ?? '').toString(),
      costumeId: (json['costumeId'] ?? '').toString(),
      costumeName: (json['costumeName'] ?? '').toString(),
      costumes: items,
      startDate: (json['startDate'] ?? '').toString(),
      duration: (json['duration'] as num?)?.toInt() ?? 1,
      totalPrice: (json['totalPrice'] as num?)?.toInt() ?? 0,
      depositFee: (json['depositFee'] as num?)?.toInt() ?? 100000,
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      couponCode: json['couponCode']?.toString(),
      status: (json['status'] ?? 'Menunggu').toString(),
      paymentMethod: (json['paymentMethod'] ?? 'QRIS').toString(),
      paymentProof: json['paymentProof']?.toString(),
      qcStatus: json['qcStatus']?.toString(),
      refundAmount: (json['refundAmount'] as num?)?.toInt(),
      deductionNote: json['deductionNote']?.toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      holdExpiresAt: json['holdExpiresAt']?.toString(),
      completedAt: json['completedAt']?.toString(),
      refundStatus: json['refundStatus']?.toString(),
      cancelReason: json['cancelReason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'costumeId': costumeId,
      'costumeName': costumeName,
      'costumes': costumes.map((e) => e.toJson()).toList(),
      'startDate': startDate,
      'duration': duration,
      'totalPrice': totalPrice,
      'depositFee': depositFee,
      'discountAmount': discountAmount,
      if (couponCode != null) 'couponCode': couponCode,
      'status': status,
      'paymentMethod': paymentMethod,
      if (paymentProof != null) 'paymentProof': paymentProof,
      if (qcStatus != null) 'qcStatus': qcStatus,
      if (refundAmount != null) 'refundAmount': refundAmount,
      if (deductionNote != null) 'deductionNote': deductionNote,
      'createdAt': createdAt,
      if (holdExpiresAt != null) 'holdExpiresAt': holdExpiresAt,
      if (completedAt != null) 'completedAt': completedAt,
      if (refundStatus != null) 'refundStatus': refundStatus,
      if (cancelReason != null) 'cancelReason': cancelReason,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userPhone,
        userEmail,
        costumeId,
        costumeName,
        costumes,
        startDate,
        duration,
        totalPrice,
        depositFee,
        discountAmount,
        couponCode,
        status,
        paymentMethod,
        paymentProof,
        qcStatus,
        refundAmount,
        deductionNote,
        createdAt,
        holdExpiresAt,
        completedAt,
        refundStatus,
        cancelReason,
      ];
}

class AdminEventModel extends Equatable {
  const AdminEventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.price,
    required this.quota,
    required this.booked,
    required this.image,
    required this.description,
    this.zonePrices,
  });

  final String id;
  final String title;
  final String date;
  final String time;
  final String location;
  final int price;
  final int quota;
  final int booked;
  final String image;
  final String description;
  final EventZonePrices? zonePrices;

  factory AdminEventModel.fromJson(Map<String, dynamic> json) {
    return AdminEventModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      quota: (json['quota'] as num?)?.toInt() ?? 0,
      booked: (json['booked'] as num?)?.toInt() ?? 0,
      image: (json['image'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      zonePrices: json['zonePrices'] is Map<String, dynamic>
          ? EventZonePrices.fromJson(json['zonePrices'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'time': time,
      'location': location,
      'price': price,
      'quota': quota,
      'booked': booked,
      'image': image,
      'description': description,
      if (zonePrices != null) 'zonePrices': zonePrices!.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        date,
        time,
        location,
        price,
        quota,
        booked,
        image,
        description,
        zonePrices,
      ];
}

class AdminTicketGateModel extends Equatable {
  const AdminTicketGateModel({
    required this.id,
    this.userId,
    required this.eventId,
    required this.eventTitle,
    required this.userName,
    required this.userPhone,
    required this.quantity,
    required this.seats,
    required this.zone,
    required this.totalPrice,
    required this.status,
    required this.bookingCode,
    required this.createdAt,
  });

  final String id;
  final String? userId;
  final String eventId;
  final String eventTitle;
  final String userName;
  final String userPhone;
  final int quantity;
  final List<String> seats;
  final String zone;
  final int totalPrice;
  final String status;
  final String bookingCode;
  final String createdAt;

  bool get isCheckedIn => status == 'Check-in';

  factory AdminTicketGateModel.fromJson(Map<String, dynamic> json) {
    return AdminTicketGateModel(
      id: (json['id'] ?? '').toString(),
      userId: json['userId']?.toString(),
      eventId: (json['eventId'] ?? '').toString(),
      eventTitle: (json['eventTitle'] ?? '').toString(),
      userName: (json['userName'] ?? '').toString(),
      userPhone: (json['userPhone'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      seats: (json['seats'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      zone: (json['zone'] ?? 'REGULER').toString(),
      totalPrice: (json['totalPrice'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'Aktif').toString(),
      bookingCode: (json['bookingCode'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'userId': userId,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'userName': userName,
      'userPhone': userPhone,
      'quantity': quantity,
      'seats': seats,
      'zone': zone,
      'totalPrice': totalPrice,
      'status': status,
      'bookingCode': bookingCode,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        eventId,
        eventTitle,
        userName,
        userPhone,
        quantity,
        seats,
        zone,
        totalPrice,
        status,
        bookingCode,
        createdAt,
      ];
}

class AdminCouponModel extends Equatable {
  const AdminCouponModel({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.minOrder,
    required this.maxUses,
    required this.usedCount,
    required this.isActive,
    required this.expiresAt,
    this.description,
  });

  final String id;
  final String code;
  final String type;
  final int value;
  final int minOrder;
  final int maxUses;
  final int usedCount;
  final bool isActive;
  final String expiresAt;
  final String? description;

  factory AdminCouponModel.fromJson(Map<String, dynamic> json) {
    return AdminCouponModel(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      type: (json['type'] ?? 'FIXED').toString(),
      value: (json['value'] as num?)?.toInt() ?? 0,
      minOrder: (json['minOrder'] as num?)?.toInt() ?? 0,
      maxUses: (json['maxUses'] as num?)?.toInt() ?? 0,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] != false,
      expiresAt: (json['expiresAt'] ?? '').toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'type': type,
      'value': value,
      'minOrder': minOrder,
      'maxUses': maxUses,
      'usedCount': usedCount,
      'isActive': isActive,
      'expiresAt': expiresAt,
      if (description != null) 'description': description,
    };
  }

  @override
  List<Object?> get props => [
        id,
        code,
        type,
        value,
        minOrder,
        maxUses,
        usedCount,
        isActive,
        expiresAt,
        description,
      ];
}

class AdminReviewModerationModel extends Equatable {
  const AdminReviewModerationModel({
    required this.id,
    required this.targetId,
    required this.targetType,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.verified = false,
    this.status = 'tampil',
  });

  final String id;
  final String targetId;
  final String targetType;
  final String userName;
  final int rating;
  final String comment;
  final String createdAt;
  final bool verified;
  final String status;

  factory AdminReviewModerationModel.fromJson(Map<String, dynamic> json) {
    return AdminReviewModerationModel(
      id: (json['id'] ?? '').toString(),
      targetId: (json['targetId'] ?? '').toString(),
      targetType: (json['targetType'] ?? 'gallery').toString(),
      userName: (json['userName'] ?? 'Pengunjung').toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: (json['comment'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      verified: json['verified'] == true,
      status: (json['status'] ?? 'tampil').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetId': targetId,
      'targetType': targetType,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
      'verified': verified,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        targetId,
        targetType,
        userName,
        rating,
        comment,
        createdAt,
        verified,
        status,
      ];
}
