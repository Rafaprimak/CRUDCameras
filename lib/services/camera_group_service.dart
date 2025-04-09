import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/camera_group.dart';

class CameraGroupService {
  static final CameraGroupService _instance = CameraGroupService._internal();
  final CollectionReference _groupsCollection = 
      FirebaseFirestore.instance.collection('cameraGroups');
  
  List<CameraGroup> _groups = [];
  final Uuid _uuid = const Uuid();
  bool _initialized = false;
  
  factory CameraGroupService() {
    return _instance;
  }
  
  CameraGroupService._internal();
  
  List<CameraGroup> get groups => List.unmodifiable(_groups);

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await getGroups();
      
      final defaultGroupExists = _groups.any((group) => 
          group.name == 'Todas as Câmeras');
      
      if (!defaultGroupExists) {
        final String newId = _uuid.v4(); 
        final defaultGroup = CameraGroup(
          id: newId, 
          name: 'Todas as Câmeras',
          description: 'Grupo padrão para todas as câmeras',
          iconName: 'videocam',
          colorValue: 0xFFffc112,
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
      final snapshot = await _groupsCollection.get();
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
  
  String get defaultGroupId => _groups.isNotEmpty ? _groups.first.id : '';

  Future<void> addGroup(CameraGroup group) async {
    final String docId = group.id.isEmpty ? _uuid.v4() : group.id;
    
    final newGroup = CameraGroup(
      id: docId,
      name: group.name,
      description: group.description,
      iconName: group.iconName,
      colorValue: group.colorValue,
    );
    
    await _groupsCollection.doc(docId).set(newGroup.toFirestore());
    
    _groups.add(newGroup);
  }

  Future<void> updateGroup(CameraGroup group) async {
    await _groupsCollection.doc(group.id).update(group.toFirestore());
    await getGroups();
  }

  Future<void> deleteGroup(String id) async {
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
}