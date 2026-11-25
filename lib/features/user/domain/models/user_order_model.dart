import 'package:equatable/equatable.dart';

class BookingCartItemModel extends Equatable {
  const BookingCartItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.days,
    required this.size,
  });

  final String id;
  final String name;
  final int price;
  final int days;
  final String size;

  int get subtotal => price * days;

  factory BookingCartItemModel.fromJson(Map<String, dynamic> json) {
    return BookingCartItemModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      days: (json['days'] as num?)?.toInt() ?? 1,
      size: (json['size'] ?? 'All Size').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'days': days,
      'size': size,
    };
  }

  BookingCartItemModel copyWith({
    String? id,
    String? name,
    int? price,
    int? days,
    String? size,
  }) {
    return BookingCartItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      days: days ?? this.days,
      size: size ?? this.size,
    );
  }

  @override
  List<Object?> get props => [id, name, price, days, size];
}

class UserOrderModel extends Equatable {
  const UserOrderModel({
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

  factory UserOrderModel.fromJson(Map<String, dynamic> json) {
    final items = (json['costumes'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(BookingCartItemModel.fromJson)
            .toList() ??
        const <BookingCartItemModel>[];

    return UserOrderModel(
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
