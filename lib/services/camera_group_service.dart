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

  // Initialize the service and ensure the default group exists
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await getGroups();
      
      // Check if default group exists
      final defaultGroupExists = _groups.any((group) => 
          group.name == 'Todas as Câmeras');
      
      // Add default group if it doesn't exist
      if (!defaultGroupExists) {
        final String newId = _uuid.v4(); // Generate valid UUID
        final defaultGroup = CameraGroup(
          id: newId, // Use the generated ID instead of empty string
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

  // Fix getGroups method to correctly cache and handle groups
  Future<List<CameraGroup>> getGroups() async {
    try {
      final snapshot = await _groupsCollection.get();
      _groups = snapshot.docs
          .map((doc) => CameraGroup.fromFirestore(doc))
          .toList();
      
      // Sort groups by name for consistent display
      _groups.sort((a, b) => a.name.compareTo(b.name));
      
      return _groups;
    } catch (e) {
      print('Error getting groups: $e');
      return _groups;
    }
  }
  
  String get defaultGroupId => _groups.isNotEmpty ? _groups.first.id : '';

  // Method for adding a new group
  Future<void> addGroup(CameraGroup group) async {
    // Generate a new ID if it's empty
    final String docId = group.id.isEmpty ? _uuid.v4() : group.id;
    
    // Create a new group with the generated ID
    final newGroup = CameraGroup(
      id: docId,
      name: group.name,
      description: group.description,
      iconName: group.iconName,
      colorValue: group.colorValue,
    );
    
    // Save to Firestore
    await _groupsCollection.doc(docId).set(newGroup.toFirestore());
    
    // Add to local cache
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

  // Add a method to check if a group is the default "all cameras" group
  bool isDefaultGroup(String groupId) {
    if (groupId.isEmpty) return true;
    
    try {
      final group = _groups.firstWhere((group) => group.id == groupId);
      return group.name == 'Todas as Câmeras';
    } catch (e) {
      return false;
    }
  }

  // Fix getGroupById for better null handling
  CameraGroup? getGroupById(String groupId) {
    if (groupId.isEmpty) {
      // Return the default group if no ID is provided
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