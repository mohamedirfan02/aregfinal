class Fbo {
  final int id;
  final String fullName;
  final String restaurantName;
  final String category;
  final String countryCode;
  final String contactNumber;
  final String email;
  final String licenseNumber;
  final String address;
  final String licenseUrl;
  final String restaurantUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Branch> branches;

  Fbo({
    required this.id,
    required this.fullName,
    required this.restaurantName,
    required this.category,
    required this.countryCode,
    required this.contactNumber,
    required this.email,
    required this.licenseNumber,
    required this.address,
    required this.licenseUrl,
    required this.restaurantUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.branches,
  });

  factory Fbo.fromJson(Map<String, dynamic> json) {
    return Fbo(
      id: json['id'],
      fullName: json['full_name'] ?? "",
      restaurantName: json['restaurant_name'] ?? "",
      category: json['category'] ?? "",
      countryCode: json['country_code'] ?? "",
      contactNumber: json['contact_number'] ?? "",
      email: json['email'] ?? "",
      licenseNumber: json['license_number'] ?? "",
      address: json['address'] ?? "",
      licenseUrl: json['license_url'] ?? "",
      restaurantUrl: json['restaurant_url'] ?? "",
      status: json['status'] ?? "",
      createdAt: DateTime.tryParse(json['created_at'] ?? "") ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? "") ?? DateTime.now(),
      branches: (json['branches'] as List<dynamic>?)
          ?.map((b) => Branch.fromJson(b))
          .toList() ??
          [],
    );
  }
}

class Branch {
  final int id;
  final int restaurantId;
  final String name;
  final String address;
  final String fssaiNo;
  final String license;
  final DateTime createdAt;
  final DateTime updatedAt;

  Branch({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.address,
    required this.fssaiNo,
    required this.license,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      name: json['name'] ?? "",
      address: json['address'] ?? "",
      fssaiNo: json['fssai_no'] ?? "",
      license: json['license'] ?? "",
      createdAt: DateTime.tryParse(json['created_at'] ?? "") ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? "") ?? DateTime.now(),
    );
  }
}
