import 'package:cloud_firestore/cloud_firestore.dart';

class CameraGroup {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final int colorValue;
  final String userId; // Add this field

  CameraGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.colorValue,
    required this.userId, // Add this parameter
  });

  factory CameraGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CameraGroup(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? 'folder',
      colorValue: data['colorValue'] ?? 0xFF9E9E9E,
      userId: data['userId'] ?? '', // Extract userId
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'iconName': iconName,
      'colorValue': colorValue,
      'userId': userId, // Include userId
    };
  }
}