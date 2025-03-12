import 'package:cloud_firestore/cloud_firestore.dart';

class StaffModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String salonId;
  final String? photoUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  StaffModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.salonId,
    this.photoUrl,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      salonId: json['salonId'] as String,
      photoUrl: json['photoUrl'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastLoginAt: json['lastLoginAt'] != null
          ? (json['lastLoginAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'salonId': salonId,
      'photoUrl': photoUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  StaffModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? salonId,
    String? photoUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return StaffModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      salonId: salonId ?? this.salonId,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
