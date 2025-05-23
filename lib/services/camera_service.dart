import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/camera.dart';
import 'camera_group_service.dart';
import '../services/auth_service.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  
  factory CameraService() {
    return _instance;
  }
  
  CameraService._internal();
  
  final CollectionReference _camerasCollection = 
      FirebaseFirestore.instance.collection('cameras');
  
  List<Camera> _cameras = [];
  final CameraGroupService _groupService = CameraGroupService();
  final AuthService _authService = AuthService();

  Future<List<Camera>> getCameras() async {
    try {
      final userId = _authService.userId;
      if (userId.isEmpty) {
        // No user logged in, return empty list
        _cameras = [];
        return _cameras;
      }
      
      // Filter cameras by userId
      final snapshot = await _camerasCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      final newCameras = snapshot.docs
          .map((doc) => Camera.fromFirestore(doc))
          .toList();
          
      if (_cameras.length != newCameras.length || 
          !_compareCameraLists(_cameras, newCameras)) {
        _cameras = newCameras;
      }
      
      return _cameras;
    } catch (e) {
      print('Error getting cameras: $e');
      return _cameras;
    }
  }
  
  bool _compareCameraLists(List<Camera> list1, List<Camera> list2) {
    if (list1.length != list2.length) return false;
    
    final map1 = {for (var c in list1) c.id: c};
    final map2 = {for (var c in list2) c.id: c};
    
    if (!map1.keys.every((id) => map2.containsKey(id))) return false;
    
    for (final id in map1.keys) {
      final cam1 = map1[id]!;
      final cam2 = map2[id]!;
      if (cam1.name != cam2.name ||
          cam1.isActive != cam2.isActive ||
          cam1.groupId != cam2.groupId) {
        return false;
      }
    }
    
    return true;
  }
  
  List<Camera> get cameras => _cameras;

  List<Camera> getCamerasByGroup(String groupId) {
    if (groupId.isEmpty || groupId == _groupService.defaultGroupId) {
      return cameras;
    }
    return _cameras.where((camera) => camera.groupId == groupId).toList();
  }

  Future<void> addCamera(Camera camera) async {
    try {
      final data = camera.toFirestore();
      
      // Debug logging
      print('Adding camera to Firestore with data:');
      print(data);
      
      // Add to Firestore
      await _camerasCollection.add(data);
      
      // Refresh cameras list
      await getCameras();
    } catch (e) {
      print('Error adding camera: $e');
      throw e;
    }
  }

  Future<void> updateCamera(Camera camera) async {
    await _camerasCollection.doc(camera.id).update(camera.toFirestore());
    
    final index = _cameras.indexWhere((c) => c.id == camera.id);
    if (index >= 0) {
      _cameras[index] = camera;
    }
    
    await getCameras();
  }

  void updateCameraGroup(String cameraId, String groupId) {
    final camera = getCameraById(cameraId);
    if (camera != null) {
      final updatedCamera = Camera(
        id: camera.id,
        name: camera.name,
        brand: camera.brand,
        model: camera.model,
        ipAddress: camera.ipAddress,
        address: camera.address,
        isActive: camera.isActive,
        groupId: groupId,
        userId: camera.userId,
      );
      updateCamera(updatedCamera);
    }
  }

  Future<void> deleteCamera(String id) async {
    await _camerasCollection.doc(id).delete();
    _cameras.removeWhere((camera) => camera.id == id);
  }

  Camera? getCameraById(String id) {
    try {
      return _cameras.firstWhere((camera) => camera.id == id);
    } catch (_) {
      return null;
    }
  }

  Stream<List<Camera>> streamCameras() {
    final userId = _authService.userId;
    if (userId.isEmpty) {
      // Return empty stream if no user is logged in
      return Stream.value([]);
    }
    
    return _camerasCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Camera.fromFirestore(doc))
          .toList();
    });
  }
}