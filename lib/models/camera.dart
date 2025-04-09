import 'package:cloud_firestore/cloud_firestore.dart';

class Camera {
  final String id;
  final String name;
  final String address;
  final String ipAddress;
  final String brand;
  final String model;
  final bool isActive;
  final String groupId;

  Camera({
    required this.id,
    required this.name,
    required this.address,
    required this.ipAddress,
    required this.brand,
    required this.model,
    required this.isActive,
    required this.groupId,
  });


  factory Camera.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Camera(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      ipAddress: data['ipAddress'] ?? '',
      brand: data['brand'] ?? '',
      model: data['model'] ?? '',
      isActive: data['isActive'] ?? true,
      groupId: data['groupId'] ?? '',
    );
  }


  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'ipAddress': ipAddress,
      'brand': brand,
      'model': model,
      'isActive': isActive,
      'groupId': groupId,
    };
  }
}