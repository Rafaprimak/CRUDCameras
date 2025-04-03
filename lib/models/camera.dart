class Camera {
  String id;
  String name;
  String brand;
  String model;
  String ipAddress;
  bool isActive;

  Camera({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.ipAddress,
    this.isActive = true,
  });

  Camera.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        brand = map['brand'],
        model = map['model'],
        ipAddress = map['ipAddress'],
        isActive = map['isActive'];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'model': model,
      'ipAddress': ipAddress,
      'isActive': isActive,
    };
  }
}