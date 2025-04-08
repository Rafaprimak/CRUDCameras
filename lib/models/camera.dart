class Camera {
  final String id;
  final String name;
  final String brand;
  final String model;
  final String ipAddress;
  final String address;
  final bool isActive;
  final String groupId; 
  Camera({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.ipAddress,
    required this.address,
    this.isActive = true,
    this.groupId = '', 
  });

  Camera.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        brand = map['brand'],
        model = map['model'],
        ipAddress = map['ipAddress'],
        address = map['address'],
        isActive = map['isActive'],
        groupId = map['groupId'] ?? ''; 

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'model': model,
      'ipAddress': ipAddress,
      'address': address,
      'isActive': isActive,
      'groupId': groupId, 
    };
  }
}