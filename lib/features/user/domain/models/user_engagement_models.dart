import 'package:equatable/equatable.dart';

class UserCouponModel extends Equatable {
  const UserCouponModel({
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
  final String type; // 'PERCENTAGE' | 'FIXED'
  final int value;
  final int minOrder;
  final int maxUses;
  final int usedCount;
  final bool isActive;
  final String expiresAt;
  final String? description;

  factory UserCouponModel.fromJson(Map<String, dynamic> json) {
    return UserCouponModel(
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

class UserReviewModel extends Equatable {
  const UserReviewModel({
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
  final String targetType; // 'costume' | 'gallery'
  final String userName;
  final int rating;
  final String comment;
  final String createdAt;
  final bool verified;
  final String status;

  factory UserReviewModel.fromJson(Map<String, dynamic> json) {
    return UserReviewModel(
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

class WishlistItemModel extends Equatable {
  const WishlistItemModel({
    required this.id,
    required this.userId,
    required this.targetId,
    required this.targetType,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String targetId;
  final String targetType; // 'gallery' | 'costume'
  final String createdAt;

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      targetId: (json['targetId'] ?? '').toString(),
      targetType: (json['targetType'] ?? 'gallery').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'targetId': targetId,
      'targetType': targetType,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [id, userId, targetId, targetType, createdAt];
}

class PublicSettingsModel extends Equatable {
  const PublicSettingsModel({
    required this.galleryName,
    required this.tagline,
    required this.openHours,
    required this.location,
    required this.phone,
    required this.email,
    required this.depositFee,
    required this.terms,
    this.notifications = true,
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

  factory PublicSettingsModel.fromJson(Map<String, dynamic> json) {
    return PublicSettingsModel(
      galleryName: (json['galleryName'] ?? 'Galeri Pusaka Seni Sriwedari').toString(),
      tagline: (json['tagline'] ?? '').toString(),
      openHours: (json['openHours'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      depositFee: (json['depositFee'] as num?)?.toInt() ?? 100000,
      terms: (json['terms'] ?? '').toString(),
      notifications: json['notifications'] != false,
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
      ];
}
