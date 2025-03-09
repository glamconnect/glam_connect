import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceCategory {
  final String id;
  final String name;
  final String? base64Image;
  final bool isActive;
  final String? parentCategoryId;
  final DateTime createdAt;
  final String createdBy;

  ServiceCategory({
    required this.id,
    required this.name,
    this.base64Image,
    required this.isActive,
    this.parentCategoryId,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'base64Image': base64Image,
      'isActive': isActive,
      'parentCategoryId': parentCategoryId,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }

  factory ServiceCategory.fromMap(Map<String, dynamic> map) {
    return ServiceCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      base64Image: map['base64Image'],
      isActive: map['isActive'] ?? false,
      parentCategoryId: map['parentCategoryId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
    );
  }
}
