import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/service_model.dart';
import 'package:glam_connect/utils/constants.dart';

final serviceProvider =
    StateNotifierProvider<ServiceNotifier, AsyncValue<List<ServiceModel>>>((
      ref,
    ) {
      return ServiceNotifier();
    });

class ServiceNotifier extends StateNotifier<AsyncValue<List<ServiceModel>>> {
  ServiceNotifier() : super(const AsyncValue.loading());

  final _firestore = FirebaseFirestore.instance;

  Future<List<ServiceModel>> getServicesBySalonId(String salonId) async {
    try {
      // Get all services for the salon
      final snapshot =
          await _firestore
              .collection(Constants.servicesCollection)
              .where('salonId', isEqualTo: salonId)
              .get();

      // Get referenced categories
      final categoryIds =
          snapshot.docs
              .map((doc) => doc.data()['categoryId'] as String)
              .toSet();

      Map<String, Map<String, dynamic>> categoryMap = {};

      // Only fetch categories if we have services
      if (categoryIds.isNotEmpty) {
        // Fetch categories in batches of 10 to avoid potential limitations
        for (var i = 0; i < categoryIds.length; i += 10) {
          final batch = categoryIds.skip(i).take(10).toList();
          final batchSnapshot =
              await _firestore
                  .collection(Constants.categoriesCollection)
                  .where(FieldPath.documentId, whereIn: batch)
                  .get();

          categoryMap.addAll(
            Map.fromEntries(
              batchSnapshot.docs.map((doc) => MapEntry(doc.id, doc.data())),
            ),
          );
        }
      }

      final services =
          snapshot.docs
              .where((doc) => doc.data()['isActive'] ?? false)
              .map((doc) {
                final data = doc.data();
                final categoryData = categoryMap[data['categoryId']];
                if (categoryData == null ||
                    !(categoryData['isActive'] ?? false)) {
                  return null;
                }
                return ServiceModel.fromJson({'id': doc.id, ...data});
              })
              .where((service) => service != null)
              .cast<ServiceModel>()
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = AsyncValue.data(services);
      return services;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return [];
    }
  }

  Future<bool> createService({
    required String name,
    required String description,
    required String price,
    required bool isActive,
    required String salonId,
    required String categoryId,
    String? base64Image,
    required String createdBy,
  }) async {
    try {
      // Verify category exists and is active
      final categoryDoc =
          await _firestore
              .collection(Constants.categoriesCollection)
              .doc(categoryId)
              .get();

      if (!categoryDoc.exists || !(categoryDoc.data()?['isActive'] ?? false)) {
        throw Exception('Selected category does not exist or is inactive');
      }

      // Ensure all fields match ServiceModel types
      // Validate required fields
      if (name.isEmpty ||
          description.isEmpty ||
          price.isEmpty ||
          salonId.isEmpty ||
          categoryId.isEmpty ||
          createdBy.isEmpty) {
        throw Exception('Required fields cannot be empty');
      }

      final serviceData = <String, dynamic>{
        'name': name.trim(),
        'description': description.trim(),
        'price': price.trim(),
        'isActive': isActive,
        'salonId': salonId.trim(),
        'categoryId': categoryId.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy.trim(),
      };

      // Only add base64Image if it's not null or empty
      if (base64Image != null && base64Image.isNotEmpty) {
        serviceData['base64Image'] = base64Image;
      }
      log('Service Data: ${serviceData.toString()}');

      await _firestore
          .collection(Constants.servicesCollection)
          .add(serviceData);

      // Refresh the services list
      await getServicesBySalonId(salonId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating service: $e');
      }
      return false;
    }
  }

  Future<bool> updateService({
    required String id,
    required String name,
    required String description,
    required double price,
    required bool isActive,
    required String salonId,
    required String categoryId,
    String? base64Image,
  }) async {
    try {
      // Verify category exists and is active
      final categoryDoc =
          await _firestore
              .collection(Constants.categoriesCollection)
              .doc(categoryId)
              .get();

      if (!categoryDoc.exists || !(categoryDoc.data()?['isActive'] ?? false)) {
        throw Exception('Selected category does not exist or is inactive');
      }

      final updateData = {
        'name': name,
        'description': description,
        'price': price,
        'isActive': isActive,
        'categoryId': categoryId,
      };

      if (base64Image != null) {
        updateData['base64Image'] = base64Image;
      }

      await _firestore
          .collection(Constants.servicesCollection)
          .doc(id)
          .update(updateData);

      await getServicesBySalonId(salonId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteService(String id, String salonId) async {
    try {
      await _firestore
          .collection(Constants.servicesCollection)
          .doc(id)
          .delete();
      await getServicesBySalonId(salonId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
