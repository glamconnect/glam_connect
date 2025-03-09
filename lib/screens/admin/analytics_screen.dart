import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/utils/app_colors.dart';
import 'package:glam_connect/utils/constants.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  int _totalSalons = 0;
  int _totalCustomers = 0;
  int _totalServices = 0;
  int _totalAppointments = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      // Get total salons
      final salonsSnapshot =
          await _firestore.collection(Constants.salonsCollection).count().get();
      _totalSalons = salonsSnapshot.count ?? 0;

      // Get total customers
      final customersSnapshot =
          await _firestore
              .collection(Constants.usersCollection)
              .where('role', isEqualTo: 'customer')
              .count()
              .get();
      _totalCustomers = customersSnapshot.count ?? 0;

      // Get total services
      final servicesSnapshot =
          await _firestore.collection('services').count().get();
      _totalServices = servicesSnapshot.count ?? 0;

      // Get total appointments
      final appointmentsSnapshot =
          await _firestore.collection('appointments').count().get();
      _totalAppointments = appointmentsSnapshot.count ?? 0;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading analytics: $e')));
      }
    }
  }

  Widget _buildAnalyticCard({
    required IconData icon,
    required String title,
    required int value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 5),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColor.primary,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadAnalytics,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildAnalyticCard(
                            icon: Icons.store,
                            title: 'Total Salons',
                            value: _totalSalons,
                            color: Colors.blue,
                          ),
                          _buildAnalyticCard(
                            icon: Icons.people,
                            title: 'Total Customers',
                            value: _totalCustomers,
                            color: Colors.green,
                          ),
                          _buildAnalyticCard(
                            icon: Icons.spa,
                            title: 'Total Services',
                            value: _totalServices,
                            color: Colors.purple,
                          ),
                          _buildAnalyticCard(
                            icon: Icons.calendar_today,
                            title: 'Total Appointments',
                            value: _totalAppointments,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
