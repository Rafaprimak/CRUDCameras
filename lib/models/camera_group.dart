
class CameraGroup {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final int colorValue;

  CameraGroup({
    required this.id,
    required this.name,
    this.description = '',
    this.iconName = 'folder',
    this.colorValue = 0xFF9E9E9E,
  });
}