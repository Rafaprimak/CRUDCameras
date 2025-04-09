
import 'package:cloud_firestore/cloud_firestore.dart';

class CameraGroup {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final int colorValue;

  CameraGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.colorValue,
  });

  factory CameraGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CameraGroup(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? '',
      colorValue: data['colorValue'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'iconName': iconName,
      'colorValue': colorValue,
    };
  }
}