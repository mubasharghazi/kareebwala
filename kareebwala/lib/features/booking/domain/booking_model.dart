import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String userName;
  final String serviceType;
  final String description;
  final String status;
  final double lat;
  final double lng;
  final String? providerId;
  final double price;
  final String? cancellationReason;
  final Timestamp? createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.userName,
    required this.serviceType,
    required this.description,
    required this.status,
    required this.lat,
    required this.lng,
    this.providerId,
    required this.price,
    this.cancellationReason,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'serviceType': serviceType,
      'description': description,
      'status': status,
      'lat': lat,
      'lng': lng,
      'providerId': providerId,
      'price': price,
      'cancellationReason': cancellationReason, // NEW
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map, String docId) {
    return Booking(
      id: docId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Unknown',
      serviceType: map['serviceType'] ?? 'Service',
      description: map['description'] ?? '',
      status: map['status'] ?? 'searching',
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
      providerId: map['providerId'],
      price: (map['price'] ?? 0.0).toDouble(),
      cancellationReason: map['cancellationReason'],
      createdAt: map['createdAt'] as Timestamp?,
    );
  }
}
