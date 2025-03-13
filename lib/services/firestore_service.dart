import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/user_model.dart';
import 'package:glam_connect/utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize Firestore with demo data (for testing)
  Future<void> initializeFirestoreWithDemoData() async {
    try {
      // Check if data already exists
      final salonsSnapshot =
          await _firestore
              .collection(Constants.salonsCollection)
              .limit(1)
              .get();
      if (salonsSnapshot.docs.isNotEmpty) {
        print('Demo data already exists');
        return;
      }

      // Add demo salons
      for (final salonData in Constants.demoSalons) {
        await _firestore
            .collection(Constants.salonsCollection)
            .doc(salonData['id'])
            .set(salonData);
      }

      // Add demo services
      for (final serviceData in Constants.demoServices) {
        await _firestore
            .collection(Constants.serviceCollection)
            .doc(serviceData['id'])
            .set(serviceData);
      }

      // Add demo employees (these would normally be in the users collection)
      for (final employeeData in Constants.demoEmployees) {
        await _firestore
            .collection(Constants.usersCollection)
            .doc(employeeData['id'])
            .set({
              'name': employeeData['name'],
              'role': employeeData['role'],
              'salonId': employeeData['salonId'],
              'specialization': employeeData['specialization'],
              'rating': employeeData['rating'],
              'imageUrl': employeeData['imageUrl'],
              'phoneNumber': '+1234567890', // Dummy phone number
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            });
      }

      print('Demo data added successfully');
    } catch (e) {
      print('Error initializing Firestore with demo data: $e');
    }
  }

  // Create a new salon
  Future<String?> createSalon({
    required String name,
    required String address,
    required String phone,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final docRef = await _firestore
          .collection(Constants.salonsCollection)
          .add({
            'name': name,
            'address': address,
            'phone': phone,
            'description': description,
            'imageUrl': imageUrl,
            'rating': 0.0,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
      return docRef.id;
    } catch (e) {
      print('Error creating salon: $e');
      return null;
    }
  }

  // Get all salons
  Future<List<Map<String, dynamic>>> getAllSalons() async {
    try {
      final querySnapshot =
          await _firestore.collection(Constants.salonsCollection).get();
      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error getting salons: $e');
      return [];
    }
  }

  // Get salon by ID
  Future<Map<String, dynamic>?> getSalonById(String salonId) async {
    try {
      final docSnapshot =
          await _firestore
              .collection(Constants.salonsCollection)
              .doc(salonId)
              .get();
      if (docSnapshot.exists) {
        return {'id': docSnapshot.id, ...docSnapshot.data()!};
      }
      return null;
    } catch (e) {
      print('Error getting salon: $e');
      return null;
    }
  }

  // Get services by salon ID
  Future<List<Map<String, dynamic>>> getServicesBySalonId(
    String salonId,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(Constants.serviceCollection)
              .where('salonId', isEqualTo: salonId)
              .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error getting services: $e');
      return [];
    }
  }

  // Get employees by salon ID
  Future<List<UserModel>> getEmployeesBySalonId(String salonId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(Constants.usersCollection)
              .where(
                'role',
                isEqualTo: UserRole.employee.toString().split('.').last,
              )
              .where('salonId', isEqualTo: salonId)
              .get();

      return querySnapshot.docs.map((doc) {
        return UserModel.fromJson({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Error getting employees: $e');
      return [];
    }
  }

  // Create a new appointment
  Future<String?> createAppointment({
    required String userId,
    required String salonId,
    required String serviceId,
    required String employeeId,
    required DateTime appointmentDateTime,
    required int duration,
    required double price,
  }) async {
    try {
      final docRef = await _firestore
          .collection(Constants.appointmentsCollection)
          .add({
            'userId': userId,
            'salonId': salonId,
            'serviceId': serviceId,
            'employeeId': employeeId,
            'appointmentDateTime': appointmentDateTime.toIso8601String(),
            'duration': duration,
            'price': price,
            'status': 'pending', // pending, confirmed, completed, cancelled
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
      return docRef.id;
    } catch (e) {
      print('Error creating appointment: $e');
      return null;
    }
  }

  // Get appointments by user ID
  Future<List<Map<String, dynamic>>> getAppointmentsByUserId(
    String userId,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(Constants.appointmentsCollection)
              .where('userId', isEqualTo: userId)
              .orderBy('appointmentDateTime', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error getting appointments: $e');
      return [];
    }
  }

  // Get appointments by employee ID
  Future<List<Map<String, dynamic>>> getAppointmentsByEmployeeId(
    String employeeId,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(Constants.appointmentsCollection)
              .where('employeeId', isEqualTo: employeeId)
              .orderBy('appointmentDateTime', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error getting appointments: $e');
      return [];
    }
  }

  // Update appointment status
  Future<bool> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      await _firestore
          .collection(Constants.appointmentsCollection)
          .doc(appointmentId)
          .update({
            'status': status,
            'updatedAt': DateTime.now().toIso8601String(),
          });
      return true;
    } catch (e) {
      print('Error updating appointment status: $e');
      return false;
    }
  }

  // Add a review
  Future<String?> addReview({
    required String userId,
    required String salonId,
    required String employeeId,
    required String appointmentId,
    required double rating,
    required String comment,
  }) async {
    try {
      final docRef = await _firestore
          .collection(Constants.reviewsCollection)
          .add({
            'userId': userId,
            'salonId': salonId,
            'employeeId': employeeId,
            'appointmentId': appointmentId,
            'rating': rating,
            'comment': comment,
            'createdAt': DateTime.now().toIso8601String(),
          });

      // Update salon rating
      await _updateSalonRating(salonId);

      // Update employee rating
      await _updateEmployeeRating(employeeId);

      return docRef.id;
    } catch (e) {
      print('Error adding review: $e');
      return null;
    }
  }

  // Update salon rating (average of all reviews)
  Future<void> _updateSalonRating(String salonId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(Constants.reviewsCollection)
              .where('salonId', isEqualTo: salonId)
              .get();

      if (querySnapshot.docs.isEmpty) return;

      double totalRating = 0;
      for (final doc in querySnapshot.docs) {
        totalRating += doc.data()['rating'] as double;
      }

      final averageRating = totalRating / querySnapshot.docs.length;

      await _firestore
          .collection(Constants.salonsCollection)
          .doc(salonId)
          .update({
            'rating': averageRating,
            'updatedAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Error updating salon rating: $e');
    }
  }

  // Update employee rating (average of all reviews)
  Future<void> _updateEmployeeRating(String employeeId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(Constants.reviewsCollection)
              .where('employeeId', isEqualTo: employeeId)
              .get();

      if (querySnapshot.docs.isEmpty) return;

      double totalRating = 0;
      for (final doc in querySnapshot.docs) {
        totalRating += doc.data()['rating'] as double;
      }

      final averageRating = totalRating / querySnapshot.docs.length;

      await _firestore
          .collection(Constants.usersCollection)
          .doc(employeeId)
          .update({
            'rating': averageRating,
            'updatedAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Error updating employee rating: $e');
    }
  }
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
