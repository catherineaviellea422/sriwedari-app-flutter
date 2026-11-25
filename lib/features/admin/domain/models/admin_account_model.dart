import 'package:equatable/equatable.dart';

class AdminAccountModel extends Equatable {
  const AdminAccountModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'admin',
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

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isActive => status == 'active';

  factory AdminAccountModel.fromJson(Map<String, dynamic> json) {
    return AdminAccountModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: (json['role'] ?? 'admin').toString(),
      status: (json['status'] ?? 'active').toString(),
      avatar: json['avatar']?.toString(),
      points: (json['points'] as num?)?.toInt() ?? 0,
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

  AdminAccountModel copyWith({
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
    return AdminAccountModel(
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
