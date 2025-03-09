import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/service_category_model.dart';
import 'package:glam_connect/utils/constants.dart';
import 'package:glam_connect/utils/image_utils.dart';

final serviceCategoryProvider =
    StateNotifierProvider<ServiceCategoryNotifier, AsyncValue<List<ServiceCategory>>>(
  (ref) => ServiceCategoryNotifier(),
);

class ServiceCategoryNotifier extends StateNotifier<AsyncValue<List<ServiceCategory>>> {
  ServiceCategoryNotifier() : super(const AsyncValue.loading()) {
    loadCategories();
  }

  final _firestore = FirebaseFirestore.instance;

  Future<void> loadCategories() async {
    try {
      final snapshot = await _firestore
          .collection(Constants.servicesCollection)
          .orderBy('createdAt', descending: true)
          .get();

      final categories = snapshot.docs
          .map((doc) => ServiceCategory.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      state = AsyncValue.data(categories);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<String?> processImage(File imageFile) async {
    try {
      return await ImageUtils.processAndEncodeImage(imageFile);
    } catch (e) {
      return null;
    }
  }

  Future<String?> createCategory({
    required String name,
    required bool isActive,
    File? imageFile,
    String? parentCategoryId,
    required String createdBy,
  }) async {
    try {
      String? base64Image;
      if (imageFile != null) {
        base64Image = await processImage(imageFile);
      }

      final docRef = await _firestore.collection(Constants.servicesCollection).add({
        'name': name,
        'base64Image': base64Image,
        'isActive': isActive,
        'parentCategoryId': parentCategoryId,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      });

      await loadCategories();
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateCategory({
    required String id,
    required String name,
    required bool isActive,
    File? newImageFile,
    String? parentCategoryId,
  }) async {
    try {
      final updateData = {
        'name': name,
        'isActive': isActive,
        'parentCategoryId': parentCategoryId,
      };

      if (newImageFile != null) {
        final base64Image = await processImage(newImageFile);
        if (base64Image != null) {
          updateData['base64Image'] = base64Image;
        }
      }

      await _firestore
          .collection(Constants.servicesCollection)
          .doc(id)
          .update(updateData);

      await loadCategories();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _firestore.collection(Constants.servicesCollection).doc(id).delete();
      await loadCategories();
      return true;
    } catch (e) {
      return false;
    }
  }
}
