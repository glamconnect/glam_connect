import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/salon_model.dart';
import 'package:glam_connect/utils/constants.dart';

final salonByIdProvider = FutureProvider.family<SalonModel?, String>((ref, salonId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection(Constants.salonsCollection)
      .doc(salonId)
      .get();

  if (!snapshot.exists) {
    return null;
  }

  return SalonModel.fromJson({...snapshot.data()!, 'id': snapshot.id});
});
