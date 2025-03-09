enum UserRole {
  customer,
  superAdmin,
  salonAdmin,
  employee,
}

class UserModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String? city;
  final UserRole role;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? salonId; // For salon admins and employees
  final String? fcmToken; // Firebase Cloud Messaging token

  UserModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.city,
    required this.role,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.salonId,
    this.fcmToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      city: json['city'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.customer,
      ),
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      salonId: json['salonId'] as String?,
      fcmToken: json['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'city': city,
      'role': role.toString().split('.').last,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'salonId': salonId,
      'fcmToken': fcmToken,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? city,
    UserRole? role,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? salonId,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      city: city ?? this.city,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      salonId: salonId ?? this.salonId,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
