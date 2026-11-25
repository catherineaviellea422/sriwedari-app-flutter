import 'package:equatable/equatable.dart';

class UserAccountModel extends Equatable {
  const UserAccountModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'user',
    this.status = 'active',
    this.avatar,
    this.points = 0,
    this.registeredAt = '',
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String? avatar;
  final int points;
  final String registeredAt;

  bool get isActive => status == 'active';

  factory UserAccountModel.fromJson(Map<String, dynamic> json) {
    return UserAccountModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      status: (json['status'] ?? 'active').toString(),
      avatar: json['avatar']?.toString(),
      points: _toInt(json['points']),
      registeredAt: (json['registeredAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      if (avatar != null) 'avatar': avatar,
      'points': points,
      'registeredAt': registeredAt,
    };
  }

  UserAccountModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? status,
    String? avatar,
    int? points,
    String? registeredAt,
  }) {
    return UserAccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      avatar: avatar ?? this.avatar,
      points: points ?? this.points,
      registeredAt: registeredAt ?? this.registeredAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        role,
        status,
        avatar,
        points,
        registeredAt,
      ];
}

int _toInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
