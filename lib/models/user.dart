import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
  });
  
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
  
  static AppUser fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      passwordHash: data['passwordHash'] ?? '',
    );
  }
}