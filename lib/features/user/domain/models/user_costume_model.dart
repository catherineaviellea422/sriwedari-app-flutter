import 'package:equatable/equatable.dart';

class UserCostumeModel extends Equatable {
  const UserCostumeModel({
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

  bool get isAvailable => stock > 0;

  factory UserCostumeModel.fromJson(Map<String, dynamic> json) {
    final rawSizes = (json['sizes'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    final rawSizeStocks = <String, int>{};
    if (json['sizeStocks'] is Map) {
      (json['sizeStocks'] as Map).forEach((k, v) {
        rawSizeStocks[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    }

    return UserCostumeModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      sizes: rawSizes,
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

  UserCostumeModel copyWith({
    String? id,
    String? name,
    String? category,
    int? price,
    double? rating,
    int? reviewCount,
    int? stock,
    List<String>? sizes,
    Map<String, int>? sizeStocks,
    String? image,
    String? description,
    String? origin,
  }) {
    return UserCostumeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      stock: stock ?? this.stock,
      sizes: sizes ?? this.sizes,
      sizeStocks: sizeStocks ?? this.sizeStocks,
      image: image ?? this.image,
      description: description ?? this.description,
      origin: origin ?? this.origin,
    );
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
