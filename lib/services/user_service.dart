import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  
  factory UserService() {
    return _instance;
  }
  
  UserService._internal();
  
  final CollectionReference _usersCollection = 
      FirebaseFirestore.instance.collection('users');
  
  // Register a new user with SHA-256 encrypted password
  Future<String> registerUser(String name, String email, String password) async {
    // Check if email is already registered
    final existingUsers = await _usersCollection
        .where('email', isEqualTo: email.toLowerCase())
        .get();
    
    if (existingUsers.docs.isNotEmpty) {
      throw 'Este email já está cadastrado';
    }
    
    // Hash the password using SHA-256
    final passwordHash = _hashPassword(password);
    
    // Create user object
    final user = AppUser(
      id: '', 
      name: name,
      email: email.toLowerCase(),
      passwordHash: passwordHash,
    );
    
    // Add user to Firestore
    final docRef = await _usersCollection.add(user.toFirestore());
    return docRef.id;
  }
  
  // Authenticate user
  Future<AppUser> loginUser(String email, String password) async {
    // Hash the password for comparison
    final passwordHash = _hashPassword(password);
    
    // Find user with matching email
    final userDocs = await _usersCollection
        .where('email', isEqualTo: email.toLowerCase())
        .get();
    
    if (userDocs.docs.isEmpty) {
      throw 'Usuário não encontrado';
    }
    
    final userDoc = userDocs.docs.first;
    final userData = userDoc.data() as Map<String, dynamic>;
    
    // Check if password matches
    if (userData['passwordHash'] != passwordHash) {
      throw 'Senha incorreta';
    }
    
    return AppUser.fromFirestore(userDoc);
  }
  
  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // Convert to bytes
    final digest = sha256.convert(bytes); // Apply SHA-256 hash
    return digest.toString();
  }
}