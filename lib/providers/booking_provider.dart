import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/booking_model.dart';
import 'package:glam_connect/models/staff_model.dart';
import 'package:glam_connect/utils/constants.dart';

final salonStaffProvider = FutureProvider.family<List<StaffModel>, String>((ref, salonId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection(Constants.staffCollection)
      .where('salonId', isEqualTo: salonId)
      .where('isActive', isEqualTo: true)
      .get();

  return snapshot.docs
      .map((doc) => StaffModel.fromJson({...doc.data(), 'id': doc.id}))
      .toList();
});

final staffAvailabilityProvider = FutureProvider.family<List<DateTime>, String>((ref, staffId) async {
  // TODO: Implement actual availability logic based on staff schedule and existing bookings
  final now = DateTime.now();
  final List<DateTime> slots = [];
  
  // For now, return next 7 days with slots from 8 AM to 3 PM
  for (int i = 0; i < 7; i++) {
    final date = DateTime(now.year, now.month, now.day + i);
    for (int hour = 8; hour <= 15; hour++) {
      slots.add(DateTime(date.year, date.month, date.day, hour));
    }
  }
  
  return slots;
});

final bookingProvider = Provider((ref) {
  final firestore = FirebaseFirestore.instance;

  return BookingService(firestore: firestore);
});

class BookingService {
  final FirebaseFirestore firestore;

  BookingService({required this.firestore});

  Future<BookingModel> createBooking({
    required String serviceId,
    required String salonId,
    required String customerId,
    String? staffId,
    required DateTime appointmentDate,
    String? note,
  }) async {
    final doc = firestore.collection(Constants.bookingsCollection).doc();
    
    final booking = BookingModel(
      id: doc.id,
      serviceId: serviceId,
      salonId: salonId,
      customerId: customerId,
      staffId: staffId,
      appointmentDate: appointmentDate,
      status: 'pending',
      note: note,
      createdAt: DateTime.now(),
    );

    await doc.set(booking.toJson());
    return booking;
  }

  Future<StaffModel?> getRandomAvailableStaff({
    required String salonId,
    required DateTime appointmentDate,
  }) async {
    final snapshot = await firestore
        .collection(Constants.staffCollection)
        .where('salonId', isEqualTo: salonId)
        .where('isActive', isEqualTo: true)
        .get();

    if (snapshot.docs.isEmpty) return null;

    // TODO: Implement actual availability check
    // For now, just return a random staff member
    final staffDocs = snapshot.docs..shuffle();
    return StaffModel.fromJson({...staffDocs.first.data(), 'id': staffDocs.first.id});
  }
}
