import 'package:flutter/material.dart';

class Constants {
  // Phone number formatting
  static String formatPhoneNumber(dynamic phoneNumber) {
    if (phoneNumber == null) return '';
    // Convert to string and remove any non-digit characters
    String cleanNumber = phoneNumber.toString().trim().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    // Ensure number is 8 digits (pad with zeros if needed)
    cleanNumber = cleanNumber.padLeft(8, '0');

    // If number already has 973 prefix, return as is
    if (cleanNumber.startsWith('973')) return cleanNumber;

    // Add 973 prefix if not present
    return '973$cleanNumber';
  }

  // App Info
  static const String appName = 'Glam Connect';
  static const String appVersion = '1.0.0';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String salonsCollection = 'salons';
  static const String categoriesCollection = 'categories';
  static const String servicesCollection = 'services';
  static const String appointmentsCollection = 'appointments';
  static const String reviewsCollection = 'reviews';

  // Shared Preferences Keys
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';

  // Navigation Routes
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String mainRoute = '/main';
  static const String salonDetailsRoute = '/salon-details';
  static const String bookingRoute = '/booking';
  static const String profileRoute = '/profile';

  // Assets
  static const String salonBackgroundImage =
      'assets/images/salon_background.png';
  static const String logoImage = 'assets/images/logo.png';

  // Demo Data (for testing)
  static final List<Map<String, dynamic>> demoSalons = [
    {
      'id': '1',
      'name': 'Glamour Beauty Salon',
      'address': '123 Main Street, New York',
      'phone': '+1234567890',
      'rating': 4.5,
      'imageUrl': 'https://example.com/salon1.jpg',
      'description': 'Luxury beauty salon offering a wide range of services.',
    },
    {
      'id': '2',
      'name': 'Elegance Hair & Spa',
      'address': '456 Park Avenue, New York',
      'phone': '+1987654321',
      'rating': 4.8,
      'imageUrl': 'https://example.com/salon2.jpg',
      'description':
          'Premium hair and spa treatments in a relaxing environment.',
    },
  ];

  static final List<Map<String, dynamic>> demoServices = [
    {
      'id': '1',
      'salonId': '1',
      'name': 'Haircut & Styling',
      'description': 'Professional haircut and styling by our experts.',
      'price': 50.0,
      'duration': 60, // in minutes
      'imageUrl': 'https://example.com/haircut.jpg',
    },
    {
      'id': '2',
      'salonId': '1',
      'name': 'Manicure & Pedicure',
      'description': 'Luxurious nail care for hands and feet.',
      'price': 40.0,
      'duration': 45, // in minutes
      'imageUrl': 'https://example.com/manicure.jpg',
    },
    {
      'id': '3',
      'salonId': '2',
      'name': 'Facial Treatment',
      'description': 'Revitalizing facial treatment for glowing skin.',
      'price': 60.0,
      'duration': 75, // in minutes
      'imageUrl': 'https://example.com/facial.jpg',
    },
  ];

  static final List<Map<String, dynamic>> demoEmployees = [
    {
      'id': 'emp1',
      'name': 'Sarah Johnson',
      'role': 'employee',
      'salonId': '1',
      'specialization': 'Hair Stylist',
      'rating': 4.7,
      'imageUrl': 'https://example.com/sarah.jpg',
    },
    {
      'id': 'emp2',
      'name': 'Michael Brown',
      'role': 'employee',
      'salonId': '1',
      'specialization': 'Nail Technician',
      'rating': 4.5,
      'imageUrl': 'https://example.com/michael.jpg',
    },
    {
      'id': 'emp3',
      'name': 'Jessica Smith',
      'role': 'employee',
      'salonId': '2',
      'specialization': 'Esthetician',
      'rating': 4.9,
      'imageUrl': 'https://example.com/jessica.jpg',
    },
  ];
}
