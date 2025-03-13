import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/service_category_model.dart';
import 'package:glam_connect/models/service_model.dart';
import 'package:glam_connect/models/salon_model.dart';
import 'package:glam_connect/models/user_model.dart';
import 'package:glam_connect/providers/service_provider.dart';
import 'package:glam_connect/providers/salon_provider.dart';
import 'package:glam_connect/utils/app_colors.dart';
import 'package:glam_connect/utils/constants.dart';
import 'package:glam_connect/screens/booking/booking_flow_screen.dart';

import '../../providers/main_provider.dart';

class CategoryServicesScreen extends ConsumerWidget {
  final ServiceCategory category;

  const CategoryServicesScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(mainProvider).currentUser;
    final servicesAsyncValue = ref.watch(
      servicesByCategoryProvider(category.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        backgroundColor: AppColor.primary,
      ),
      body: servicesAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (services) {
          if (services.isEmpty) {
            return const Center(
              child: Text('No services available in this category'),
            );
          }

          if (services.isEmpty) {
            return const Center(
              child: Text('No services available in this category'),
            );
          }

          // Group services by salon
          final servicesBySalon = <String, List<ServiceModel>>{};
          for (final service in services) {
            if (!servicesBySalon.containsKey(service.salonId)) {
              servicesBySalon[service.salonId] = [];
            }
            servicesBySalon[service.salonId]!.add(service);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: 120,
            ),
            itemCount: servicesBySalon.length,
            itemBuilder: (context, index) {
              final salonId = servicesBySalon.keys.elementAt(index);
              final salonServices = servicesBySalon[salonId]!;

              return ref
                  .watch(salonByIdProvider(salonId))
                  .when(
                    loading: () => const SizedBox(),
                    error: (error, _) => const SizedBox(),
                    data: (salon) {
                      if (salon == null) return const SizedBox();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Salon Header
                          if (index > 0) const SizedBox(height: 32),
                          Row(
                            children: [
                              if (salon.profileImageBase64 != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.memory(
                                    base64Decode(salon.profileImageBase64!),
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.store),
                                ),
                              const SizedBox(width: 12),
                              Text(
                                salon.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Services List
                          ...salonServices.map(
                            (service) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ServiceCard(
                                service: service,
                                salon: salon,
                                showSalonInfo: false,
                                userRole: currentUser?.role,
                                category: category,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
            },
          );
        },
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final SalonModel? salon;
  final bool showSalonInfo;
  final UserRole? userRole;
  final ServiceCategory category;

  const ServiceCard({
    super.key,
    required this.service,
    this.salon,
    this.showSalonInfo = true,
    this.userRole,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Service Image
          if (service.base64Image != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.memory(
                base64Decode(service.base64Image!),
                height: 200,
                fit: BoxFit.cover,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salon Info if available and requested
                if (showSalonInfo && salon != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.store, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        salon!.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Title
                Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  service.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Services List
                if (service.description.contains('Our Services:')) ...[
                  ...service.description
                      .split('Our Services:')
                      .last
                      .split('✓')
                      .where((s) => s.trim().isNotEmpty)
                      .map(
                        (service) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: AppColor.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  service.trim(),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 16),
                ],

                // Price and Book Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Price',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'BHD ${service.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary,
                          ),
                        ),
                      ],
                    ),
                    // Show Book Now button for customers and guests
                    if (userRole == UserRole.customer || userRole == null)
                      ElevatedButton(
                        onPressed: () async {
                          if (userRole == null) {
                            // Show login prompt for guests
                            showCupertinoDialog(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text('Login Required'),
                                content: const Text(
                                  'Please login to book services.',
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('Cancel'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  CupertinoDialogAction(
                                    child: const Text('Login'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      // Navigate to login screen
                                      Navigator.pushNamed(
                                        context,
                                        Constants.loginRoute,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // Show booking flow for customers
                            final result = await showCupertinoModalPopup(
                              context: context,
                              builder: (context) => BookingFlowScreen(
                                service: service,
                                category: category!,
                              ),
                            );

                            if (result == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Booking created successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
