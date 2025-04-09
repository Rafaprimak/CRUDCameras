import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/camera_group.dart';
import '../services/auth_service.dart';

class CameraGroupService {
  static final CameraGroupService _instance = CameraGroupService._internal();
  final CollectionReference _groupsCollection = 
      FirebaseFirestore.instance.collection('cameraGroups');
  
  List<CameraGroup> _groups = [];
  final Uuid _uuid = const Uuid();
  bool _initialized = false;
  final AuthService _authService = AuthService();
  
  factory CameraGroupService() {
    return _instance;
  }
  
  CameraGroupService._internal();
  
  List<CameraGroup> get groups => _groups;

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await getGroups();
      
      final userId = _authService.userId;
      if (userId.isEmpty) {
        // No user logged in, don't create default group
        _initialized = true;
        return;
      }
      
      final defaultGroupExists = _groups.any((group) => 
          group.name == 'Todas as Câmeras' && group.userId == userId);
      
      if (!defaultGroupExists) {
        final String newId = _uuid.v4(); 
        final defaultGroup = CameraGroup(
          id: newId, 
          name: 'Todas as Câmeras',
          description: 'Grupo padrão para todas as câmeras',
          iconName: 'videocam',
          colorValue: 0xFFffc112,
          userId: userId,
        );
        
        try {
          await _groupsCollection.doc(defaultGroup.id).set(defaultGroup.toFirestore());
          _groups.add(defaultGroup);
        } catch (e) {
          print('Error creating default group: $e');
          _groups.add(defaultGroup);
        }
      }
      
      _initialized = true;
    } catch (e) {
      print('Error initializing CameraGroupService: $e');
      _initialized = true;
    }
  }

  Future<List<CameraGroup>> getGroups() async {
    try {
      final userId = _authService.userId;
      if (userId.isEmpty) {
        // No user logged in, return empty list
        _groups = [];
        return _groups;
      }
      
      final snapshot = await _groupsCollection
          .where('userId', isEqualTo: userId)
          .get();
          
      _groups = snapshot.docs
          .map((doc) => CameraGroup.fromFirestore(doc))
          .toList();
      
      _groups.sort((a, b) => a.name.compareTo(b.name));
      
      return _groups;
    } catch (e) {
      print('Error getting groups: $e');
      return _groups;
    }
  }
  
  String get defaultGroupId {
    try {
      // First try to find the default group by name
      final defaultGroup = _groups.firstWhere(
        (group) => group.name == 'Todas as Câmeras' && group.userId == _authService.userId,
        orElse: () => _groups.isNotEmpty ? _groups.first : CameraGroup(
          id: '',
          name: '',
          description: '',
          iconName: 'folder',
          colorValue: 0xFF9E9E9E,
          userId: _authService.userId,
        ),
      );
      return defaultGroup.id;
    } catch (e) {
      print('Error getting default group ID: $e');
      return '';
    }
  }

  Future<void> addGroup(CameraGroup group) async {
    final String docId = group.id.isEmpty ? _uuid.v4() : group.id;
    
    final newGroup = CameraGroup(
      id: docId,
      name: group.name,
      description: group.description,
      iconName: group.iconName,
      colorValue: group.colorValue,
      userId: _authService.userId,
    );
    
    await _groupsCollection.doc(docId).set(newGroup.toFirestore());
    
    _groups.add(newGroup);
  }

  Future<void> updateGroup(CameraGroup group) async {
    await _groupsCollection.doc(group.id).update(group.toFirestore());
    await getGroups();
  }

  Future<void> deleteGroup(String id) async {
    // Don't allow deleting the default group
    if (isDefaultGroup(id)) {
      throw 'O grupo "Todas as Câmeras" não pode ser excluído.';
    }
    
    await _groupsCollection.doc(id).delete();
    _groups.removeWhere((group) => group.id == id);
  }

  bool isDefaultGroup(String groupId) {
    if (groupId.isEmpty) return true;
    
    try {
      final group = _groups.firstWhere((group) => group.id == groupId);
      return group.name == 'Todas as Câmeras';
    } catch (e) {
      return false;
    }
  }

  CameraGroup? getGroupById(String groupId) {
    if (groupId.isEmpty) {
      return _groups.firstWhere(
        (group) => group.name == 'Todas as Câmeras',
        orElse: () => _groups.first,
      );
    }
    
    try {
      return _groups.firstWhere((group) => group.id == groupId);
    } catch (e) {
      print('Group with ID $groupId not found');
      return null;
    }
  }

  Future<void> ensureDefaultGroupExists() async {
    try {
      final userId = _authService.userId;
      if (userId.isEmpty) return;
      
      await getGroups(); // Refresh groups list
      
      final defaultGroupExists = _groups.any((group) => 
        group.name == 'Todas as Câmeras' && group.userId == userId);
      
      if (!defaultGroupExists) {
        print('Default group not found. Creating new one...');
        
        final String newId = _uuid.v4();
        final defaultGroup = CameraGroup(
          id: newId,
          name: 'Todas as Câmeras',
          description: 'Grupo padrão para todas as câmeras',
          iconName: 'videocam',
          colorValue: 0xFFffc112,
          userId: userId,
        );
        
        await _groupsCollection.doc(newId).set(defaultGroup.toFirestore());
        _groups.add(defaultGroup);
        print('Default group created with ID: $newId');
      }
    } catch (e) {
      print('Error ensuring default group exists: $e');
    }
  }

  void setGroups(List<CameraGroup> groups) {
    _groups = groups;
  }
}