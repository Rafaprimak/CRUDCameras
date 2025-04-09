import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/camera.dart';
import 'camera_group_service.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  
  factory CameraService() {
    return _instance;
  }
  
  CameraService._internal();
  
  final CollectionReference _camerasCollection = 
      FirebaseFirestore.instance.collection('cameras');
  
  // Cache cameras locally
  List<Camera> _cameras = [];
  // Removed unused _uuid field
  final CameraGroupService _groupService = CameraGroupService();

  // Get all cameras (with local caching)
  Future<List<Camera>> getCameras() async {
    try {
      final snapshot = await _camerasCollection.get();
      final newCameras = snapshot.docs
          .map((doc) => Camera.fromFirestore(doc))
          .toList();
          
      // Only update if there are actual changes to avoid triggering state updates
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
  
  // Helper method to compare camera lists for equality
  bool _compareCameraLists(List<Camera> list1, List<Camera> list2) {
    if (list1.length != list2.length) return false;
    
    // Create maps of ID to last update for faster comparison
    final map1 = {for (var c in list1) c.id: c};
    final map2 = {for (var c in list2) c.id: c};
    
    // Check if all IDs match
    if (!map1.keys.every((id) => map2.containsKey(id))) return false;
    
    // Check if any camera details differ
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
  
  // Get cameras (cached)
  List<Camera> get cameras => _cameras;

  // Get cameras by group
  List<Camera> getCamerasByGroup(String groupId) {
    if (groupId.isEmpty || groupId == _groupService.defaultGroupId) {
      return cameras;
    }
    return _cameras.where((camera) => camera.groupId == groupId).toList();
  }

  // Add a new camera
  Future<void> addCamera(Camera camera) async {
    await _camerasCollection.add(camera.toFirestore());
    await getCameras(); // Refresh cache
  }

  // Improve the updateCamera method to ensure proper caching
  Future<void> updateCamera(Camera camera) async {
    await _camerasCollection.doc(camera.id).update(camera.toFirestore());
    
    // Update the cached camera immediately
    final index = _cameras.indexWhere((c) => c.id == camera.id);
    if (index >= 0) {
      _cameras[index] = camera;
    }
    
    // Also refresh from Firestore to ensure consistency
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
      );
      updateCamera(updatedCamera);
    }
  }

  // Delete a camera
  Future<void> deleteCamera(String id) async {
    await _camerasCollection.doc(id).delete();
    _cameras.removeWhere((camera) => camera.id == id);
  }

  // Get a camera by ID
  Camera? getCameraById(String id) {
    try {
      return _cameras.firstWhere((camera) => camera.id == id);
    } catch (_) {
      return null;
    }
  }

  // Stream cameras for real-time updates
  Stream<List<Camera>> streamCameras() {
    return _camerasCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Camera.fromFirestore(doc))
          .toList();
    });
  }
}