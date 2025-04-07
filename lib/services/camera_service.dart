import 'package:uuid/uuid.dart';

import '../models/camera.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  
  factory CameraService() {
    return _instance;
  }
  
  CameraService._internal();
  
  final List<Camera> _cameras = [];
  final Uuid _uuid = const Uuid();

  List<Camera> get cameras => List.unmodifiable(_cameras);

  Camera addCamera(String name, String brand, String model, String ipAddress, String address, {bool isActive = true}) {
    final camera = Camera(
      id: _uuid.v4(),
      name: name,
      brand: brand,
      model: model,
      ipAddress: ipAddress,
      address: address,
      isActive: isActive,  // Now accepts the parameter value
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