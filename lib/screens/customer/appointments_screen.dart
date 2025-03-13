import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/booking_model.dart';
import 'package:glam_connect/models/service_model.dart';
import 'package:glam_connect/models/staff_model.dart';
import 'package:glam_connect/providers/main_provider.dart';
import 'package:glam_connect/utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final userAppointmentsProvider = FutureProvider.autoDispose<List<AppointmentData>>((ref) async {
  final currentUser = ref.watch(mainProvider).currentUser;
  if (currentUser == null) return [];
  
  // Get all bookings for the current user without ordering (to avoid index requirement)
  final snapshot = await FirebaseFirestore.instance
      .collection('bookings')
      .where('customerId', isEqualTo: currentUser.id)
      .get();
      
  // We'll sort the results in memory instead

  
  final List<AppointmentData> appointments = [];
  
  for (final doc in snapshot.docs) {
    final booking = BookingModel.fromJson({...doc.data(), 'id': doc.id});
    
    // Fetch service details
    final serviceDoc = await FirebaseFirestore.instance
        .collection('services')
        .doc(booking.serviceId)
        .get();
    
    ServiceModel? service;
    if (serviceDoc.exists) {
      service = ServiceModel.fromJson({...serviceDoc.data()!, 'id': serviceDoc.id});
    }
    
    // Fetch staff details if staffId exists
    StaffModel? staff;
    if (booking.staffId != null) {
      final staffDoc = await FirebaseFirestore.instance
          .collection('staff')
          .doc(booking.staffId)
          .get();
      
      if (staffDoc.exists) {
        staff = StaffModel.fromJson({...staffDoc.data()!, 'id': staffDoc.id});
      }
    }
    
    appointments.add(AppointmentData(
      booking: booking,
      service: service,
      staff: staff,
    ));
  }
  
  // Sort appointments by date (ascending)
  appointments.sort((a, b) => a.booking.appointmentDate.compareTo(b.booking.appointmentDate));
  return appointments;
});

class AppointmentData {
  final BookingModel booking;
  final ServiceModel? service;
  final StaffModel? staff;
  
  AppointmentData({
    required this.booking,
    this.service,
    this.staff,
  });
}

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(userAppointmentsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: appointmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (appointments) {
          final now = DateTime.now();
          
          // Filter appointments into upcoming and past
          final upcomingAppointments = appointments
              .where((a) => a.booking.appointmentDate.isAfter(now))
              .toList();
          
          final pastAppointments = appointments
              .where((a) => a.booking.appointmentDate.isBefore(now))
              .toList();
          
          return TabBarView(
            controller: _tabController,
            children: [
              // Upcoming appointments tab
              _buildAppointmentsList(upcomingAppointments, isUpcoming: true),
              
              // Past appointments tab
              _buildAppointmentsList(pastAppointments, isUpcoming: false),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildAppointmentsList(List<AppointmentData> appointments, {required bool isUpcoming}) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_available : Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming 
                  ? 'No upcoming appointments' 
                  : 'No past appointments',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (isUpcoming)
              ElevatedButton(
                onPressed: () {
                  // Navigate to booking screen
                  Navigator.of(context).pushNamed('/services');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Book an Appointment'),
              ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(appointment, isUpcoming);
      },
    );
  }
  
  Widget _buildAppointmentCard(AppointmentData appointment, bool isUpcoming) {
    final booking = appointment.booking;
    final service = appointment.service;
    final staff = appointment.staff;
    
    // Format date and time
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final timeFormat = DateFormat('h:mm a');
    final formattedDate = dateFormat.format(booking.appointmentDate);
    final formattedTime = timeFormat.format(booking.appointmentDate);
    
    // Determine status color
    Color statusColor;
    switch (booking.status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    service?.name ?? 'Unknown Service',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  formattedTime,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            if (staff != null) ...[  
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    staff.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
            if (booking.note != null && booking.note!.isNotEmpty) ...[  
              const SizedBox(height: 12),
              const Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                booking.note!,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            if (isUpcoming) ...[  
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      _showCancelDialog(booking);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _showRescheduleDialog(booking);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reschedule'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showCancelDialog(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelAppointment(booking);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _cancelAppointment(BookingModel booking) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id)
          .update({'status': 'cancelled'});
      
      // Refresh the appointments
      await ref.refresh(userAppointmentsProvider.future);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling appointment: $e')),
        );
      }
    }
  }
  
  void _showRescheduleDialog(BookingModel booking) {
    // In a real app, you would implement a date/time picker here
    // For now, just show a message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Appointment'),
        content: const Text('Rescheduling functionality will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
