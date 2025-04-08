import 'package:uuid/uuid.dart';
import '../models/camera_group.dart';

class CameraGroupService {
  static final CameraGroupService _instance = CameraGroupService._internal();
  
  factory CameraGroupService() {
    return _instance;
  }
  
  CameraGroupService._internal() {
    addGroup('Todas as Câmeras', description: 'Grupo padrão para todas as câmeras', iconName: 'videocam', colorValue: 0xFFffc112);
  }
  
  final List<CameraGroup> _groups = [];
  final Uuid _uuid = const Uuid();

  List<CameraGroup> get groups => List.unmodifiable(_groups);

  String get defaultGroupId => _groups.isNotEmpty ? _groups.first.id : '';

  CameraGroup addGroup(String name, {String description = '', String iconName = 'folder', int colorValue = 0xFF9E9E9E}) {
    final group = CameraGroup(
      id: _uuid.v4(),
      name: name,
      description: description,
      iconName: iconName,
      colorValue: colorValue,
    );
    _groups.add(group);
    return group;
  }

  void updateGroup(CameraGroup group) {
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = group;
    }
  }

  void deleteGroup(String id) {
    if (id != defaultGroupId) {
      _groups.removeWhere((group) => group.id == id);
    }
  }

  CameraGroup? getGroupById(String id) {
    try {
      return _groups.firstWhere((group) => group.id == id);
    } catch (_) {
      return null;
    }
  }
}