import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String serviceId;
  final String salonId;
  final String customerId;
  final String? staffId;
  final DateTime appointmentDate;
  final String status;
  final String? note;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.serviceId,
    required this.salonId,
    required this.customerId,
    this.staffId,
    required this.appointmentDate,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      serviceId: json['serviceId'] ?? '',
      salonId: json['salonId'] ?? '',
      customerId: json['customerId'] ?? '',
      staffId: json['staffId'],
      appointmentDate: (json['appointmentDate'] as Timestamp).toDate(),
      status: json['status'] ?? 'pending',
      note: json['note'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'salonId': salonId,
      'customerId': customerId,
      'staffId': staffId,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'status': status,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
