import '../models/user.dart';

// Singleton class to hold current user state
class AuthService {
  static final AuthService _instance = AuthService._internal();
  
  factory AuthService() {
    return _instance;
  }
  
  AuthService._internal();

  AppUser? _currentUser;
  
  AppUser? get currentUser => _currentUser;
  String get userId => _currentUser?.id ?? '';
  
  bool get isLoggedIn => _currentUser != null;
  
  void setCurrentUser(AppUser user) {
    _currentUser = user;
  }
  
  void logout() {
    _currentUser = null;
  }
}