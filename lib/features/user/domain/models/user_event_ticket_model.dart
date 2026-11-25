import 'package:equatable/equatable.dart';

class EventZonePrices extends Equatable {
  const EventZonePrices({
    required this.vip,
    required this.reguler,
    required this.balkon,
  });

  final int vip;
  final int reguler;
  final int balkon;

  factory EventZonePrices.fromJson(Map<String, dynamic> json) {
    return EventZonePrices(
      vip: (json['VIP'] as num?)?.toInt() ?? 50000,
      reguler: (json['REGULER'] as num?)?.toInt() ?? 35000,
      balkon: (json['BALKON'] as num?)?.toInt() ?? 25000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'VIP': vip,
      'REGULER': reguler,
      'BALKON': balkon,
    };
  }

  int priceForZone(String zone) {
    return switch (zone.toUpperCase()) {
      'VIP' => vip,
      'REGULER' => reguler,
      'BALKON' => balkon,
      _ => reguler,
    };
  }

  @override
  List<Object?> get props => [vip, reguler, balkon];
}

class UserEventModel extends Equatable {
  const UserEventModel({
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

  int get remainingQuota => (quota - booked).clamp(0, quota);

  factory UserEventModel.fromJson(Map<String, dynamic> json) {
    return UserEventModel(
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

class UserTicketModel extends Equatable {
  const UserTicketModel({
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

  factory UserTicketModel.fromJson(Map<String, dynamic> json) {
    return UserTicketModel(
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
