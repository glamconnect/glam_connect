class SalonModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? address;
  final String? city;
  final String? description;
  final String? profileImageBase64;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String adminId; // Reference to the salon admin user

  SalonModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.address,
    this.city,
    this.description,
    this.profileImageBase64,
    required this.createdAt,
    required this.updatedAt,
    required this.adminId,
  });

  factory SalonModel.fromJson(Map<String, dynamic> json) {
    return SalonModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      address: json['address'],
      city: json['city'],
      description: json['description'],
      profileImageBase64: json['profileImageBase64'],
      adminId: json['adminId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'city': city,
      'description': description,
      'profileImageBase64': profileImageBase64,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'adminId': adminId,
    };
  }

  SalonModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? address,
    String? city,
    String? description,
    String? profileImageBase64,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminId,
  }) {
    return SalonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      description: description ?? this.description,
      profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminId: adminId ?? this.adminId,
    );
  }
}
