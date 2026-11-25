import 'package:equatable/equatable.dart';

class AdminGalleryModel extends Equatable {
  const AdminGalleryModel({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryName,
    required this.type,
    required this.date,
    required this.description,
    required this.image,
    this.views = 0,
    this.likes = 0,
    this.origin = '',
    this.costumeId,
  });

  final String id;
  final String title;
  final String category;
  final String categoryName;
  final String type;
  final String date;
  final String description;
  final String image;
  final int views;
  final int likes;
  final String origin;
  final String? costumeId;

  factory AdminGalleryModel.fromJson(Map<String, dynamic> json) {
    return AdminGalleryModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      categoryName: (json['categoryName'] ?? json['category'] ?? '').toString(),
      type: (json['type'] ?? 'foto').toString(),
      date: (json['date'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      views: (json['views'] as num?)?.toInt() ?? 0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      origin: (json['origin'] ?? '').toString(),
      costumeId: json['costumeId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'categoryName': categoryName,
      'type': type,
      'date': date,
      'description': description,
      'image': image,
      'views': views,
      'likes': likes,
      'origin': origin,
      if (costumeId != null) 'costumeId': costumeId,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        categoryName,
        type,
        date,
        description,
        image,
        views,
        likes,
        origin,
        costumeId,
      ];
}

class AdminCategoryModel extends Equatable {
  const AdminCategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    this.count = 0,
  });

  final String id;
  final String name;
  final String icon;
  final String description;
  final int count;

  factory AdminCategoryModel.fromJson(Map<String, dynamic> json) {
    return AdminCategoryModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      icon: (json['icon'] ?? 'category').toString(),
      description: (json['description'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'count': count,
    };
  }

  @override
  List<Object?> get props => [id, name, icon, description, count];
}

class AdminCostumeModel extends Equatable {
  const AdminCostumeModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.rating = 5.0,
    this.reviewCount = 0,
    this.stock = 0,
    this.sizes = const [],
    this.sizeStocks = const {},
    required this.image,
    required this.description,
    this.origin = '',
  });

  final String id;
  final String name;
  final String category;
  final int price;
  final double rating;
  final int reviewCount;
  final int stock;
  final List<String> sizes;
  final Map<String, int> sizeStocks;
  final String image;
  final String description;
  final String origin;

  factory AdminCostumeModel.fromJson(Map<String, dynamic> json) {
    final rawSizeStocks = <String, int>{};
    if (json['sizeStocks'] is Map) {
      (json['sizeStocks'] as Map).forEach((k, v) {
        rawSizeStocks[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    }

    return AdminCostumeModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      sizes: (json['sizes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      sizeStocks: rawSizeStocks,
      image: (json['image'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      origin: (json['origin'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'rating': rating,
      'reviewCount': reviewCount,
      'stock': stock,
      'sizes': sizes,
      if (sizeStocks.isNotEmpty) 'sizeStocks': sizeStocks,
      'image': image,
      'description': description,
      'origin': origin,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        price,
        rating,
        reviewCount,
        stock,
        sizes,
        sizeStocks,
        image,
        description,
        origin,
      ];
}

class StockMovementModel extends Equatable {
  const StockMovementModel({
    required this.id,
    required this.costumeId,
    required this.costumeName,
    required this.size,
    required this.delta,
    required this.stockAfter,
    required this.reason,
    this.note,
    required this.actorName,
    this.orderId,
    required this.createdAt,
  });

  final String id;
  final String costumeId;
  final String costumeName;
  final String size;
  final int delta;
  final int stockAfter;
  final String reason;
  final String? note;
  final String actorName;
  final String? orderId;
  final String createdAt;

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(
      id: (json['id'] ?? '').toString(),
      costumeId: (json['costumeId'] ?? '').toString(),
      costumeName: (json['costumeName'] ?? '').toString(),
      size: (json['size'] ?? 'All Size').toString(),
      delta: (json['delta'] as num?)?.toInt() ?? 0,
      stockAfter: (json['stockAfter'] as num?)?.toInt() ?? 0,
      reason: (json['reason'] ?? 'koreksi').toString(),
      note: json['note']?.toString(),
      actorName: (json['actorName'] ?? 'Admin').toString(),
      orderId: json['orderId']?.toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'costumeId': costumeId,
      'costumeName': costumeName,
      'size': size,
      'delta': delta,
      'stockAfter': stockAfter,
      'reason': reason,
      if (note != null) 'note': note,
      'actorName': actorName,
      if (orderId != null) 'orderId': orderId,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        costumeId,
        costumeName,
        size,
        delta,
        stockAfter,
        reason,
        note,
        actorName,
        orderId,
        createdAt,
      ];
}
