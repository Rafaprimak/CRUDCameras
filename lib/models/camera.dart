class Camera {
  String id;
  String name;
  String brand;
  String model;
  String ipAddress;
  String address; 
  bool isActive;

  Camera({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.ipAddress,
    required this.address, 
    this.isActive = true,
  });

  Camera.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        brand = map['brand'],
        model = map['model'],
        ipAddress = map['ipAddress'],
        address = map['address'], 
        isActive = map['isActive'];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'model': model,
      'ipAddress': ipAddress,
      'address': address, 
      'isActive': isActive,
    };
  }
}