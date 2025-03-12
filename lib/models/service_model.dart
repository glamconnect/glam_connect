import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool isActive;
  final String salonId;
  final String categoryId;
  final String? subCategoryId;
  final String? base64Image;
  final DateTime createdAt;
  final String createdBy;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isActive,
    required this.salonId,
    required this.categoryId,
    this.subCategoryId,
    this.base64Image,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'isActive': isActive,
      'salonId': salonId,
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'base64Image': base64Image,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: double.parse(json['price'].toString()),
      isActive: json['isActive'] as bool,
      salonId: json['salonId'] as String,
      categoryId: json['categoryId'] as String,
      subCategoryId: json['subCategoryId'] as String?,
      base64Image: json['base64Image'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      createdBy: json['createdBy'] as String,
    );
  }
}
