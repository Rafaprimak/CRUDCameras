import 'package:uuid/uuid.dart';

import '../models/camera.dart';
import 'camera_group_service.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  
  factory CameraService() {
    return _instance;
  }
  
  CameraService._internal();
  
  final List<Camera> _cameras = [];
  final Uuid _uuid = const Uuid();
  final CameraGroupService _groupService = CameraGroupService();

  List<Camera> get cameras => List.unmodifiable(_cameras);

  List<Camera> getCamerasByGroup(String groupId) {
    if (groupId.isEmpty || groupId == _groupService.defaultGroupId) {
      return cameras;
    }
    return _cameras.where((camera) => camera.groupId == groupId).toList();
  }

  Camera addCamera(String name, String brand, String model, String ipAddress, String address, {bool isActive = true, String groupId = ''}) {
    final camera = Camera(
      id: _uuid.v4(),
      name: name,
      brand: brand,
      model: model,
      ipAddress: ipAddress,
      address: address,
      isActive: isActive,
      groupId: groupId.isEmpty ? _groupService.defaultGroupId : groupId,
    );
    _cameras.add(camera);
    return camera;
  }

  void updateCamera(Camera camera) {
    final index = _cameras.indexWhere((c) => c.id == camera.id);
    if (index != -1) {
      _cameras[index] = camera;
    }
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

  void deleteCamera(String id) {
    _cameras.removeWhere((camera) => camera.id == id);
  }

  Camera? getCameraById(String id) {
    try {
      return _cameras.firstWhere((camera) => camera.id == id);
    } catch (_) {
      return null;
    }
  }
}