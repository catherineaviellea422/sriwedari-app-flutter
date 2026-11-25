import 'package:equatable/equatable.dart';

class UserGalleryModel extends Equatable {
  const UserGalleryModel({
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
    this.isLiked = false,
    this.origin = '',
    this.costumeId,
  });

  final String id;
  final String title;
  final String category;
  final String categoryName;
  final String type; // 'foto' | 'video'
  final String date;
  final String description;
  final String image;
  final int views;
  final int likes;
  final bool isLiked;
  final String origin;
  final String? costumeId;

  bool get isVideo => type.toLowerCase() == 'video';

  factory UserGalleryModel.fromJson(Map<String, dynamic> json) {
    return UserGalleryModel(
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
      isLiked: json['isLiked'] == true,
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
      'isLiked': isLiked,
      'origin': origin,
      if (costumeId != null) 'costumeId': costumeId,
    };
  }

  UserGalleryModel copyWith({
    String? id,
    String? title,
    String? category,
    String? categoryName,
    String? type,
    String? date,
    String? description,
    String? image,
    int? views,
    int? likes,
    bool? isLiked,
    String? origin,
    String? costumeId,
  }) {
    return UserGalleryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      categoryName: categoryName ?? this.categoryName,
      type: type ?? this.type,
      date: date ?? this.date,
      description: description ?? this.description,
      image: image ?? this.image,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      origin: origin ?? this.origin,
      costumeId: costumeId ?? this.costumeId,
    );
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
        isLiked,
        origin,
        costumeId,
      ];
}

class UserCategoryModel extends Equatable {
  const UserCategoryModel({
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

  factory UserCategoryModel.fromJson(Map<String, dynamic> json) {
    return UserCategoryModel(
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
