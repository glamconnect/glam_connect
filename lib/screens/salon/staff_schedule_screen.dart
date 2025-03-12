import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/staff_model.dart';
import 'package:glam_connect/providers/staff_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../utils/app_colors.dart';
import '../../widgets/common/custom_button.dart';

class StaffScheduleScreen extends ConsumerStatefulWidget {
  final String salonId;

  const StaffScheduleScreen({super.key, required this.salonId});

  @override
  ConsumerState<StaffScheduleScreen> createState() =>
      _StaffScheduleScreenState();
}

class _StaffScheduleScreenState extends ConsumerState<StaffScheduleScreen> {
  List<StaffModel> _staffList = [];
  StaffModel? _selectedStaff;
  List<DateTime> _scheduledDates = [];
  DateTime? _selectedDate;
  Map<String, List<TimeOfDay>> _timeSlots = {};

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    if (!mounted) return;
    
    final staffList = await ref
        .read(staffProvider.notifier)
        .getStaffBySalonId(widget.salonId);
        
    if (!mounted) return;
    
    setState(() {
      _staffList = staffList;
      // Select first active staff by default if available
      _selectedStaff = staffList.where((staff) => staff.isActive).firstOrNull;
    });
    if (_selectedStaff != null) {
      await _loadScheduledDates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<StaffModel>(
                    value: _selectedStaff,
                    decoration: InputDecoration(
                      labelText: 'Select Staff',
                      labelStyle: const TextStyle(color: Colors.grey),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColor.primary,
                          width: 2,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    items:
                        _staffList
                            .where((staff) => staff.isActive)
                            .map(
                              (staff) => DropdownMenuItem(
                                value: staff,
                                child: Text(staff.name),
                              ),
                            )
                            .toList(),
                    onChanged: (StaffModel? value) {
                      setState(() {
                        _selectedStaff = value;
                        _selectedDate = null;
                        _timeSlots.clear();
                      });
                      if (value != null) {
                        _loadScheduledDates();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: InkWell(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColor.primary,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          onTap: () {
                            if (_selectedStaff == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select a staff member first',
                                  ),
                                ),
                              );
                              return;
                            }
                            _showDatePicker();
                          },
                        ),
                      ),
                      Expanded(
                        child:
                            _scheduledDates.isEmpty
                                ? const Center(
                                  child: Text(
                                    'No scheduled dates',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                )
                                : ListView.builder(
                                  padding: const EdgeInsets.all(8.0),
                                  itemCount: _scheduledDates.length,
                                  itemBuilder: (context, index) {
                                    final date = _scheduledDates[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10.0,
                                      ),
                                      child: InkWell(
                                        onTap: () => _selectDate(date),
                                        borderRadius: BorderRadius.circular(50),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                _isDateSelected(date)
                                                    ? AppColor.primary
                                                    : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            border: Border.all(
                                              color: AppColor.primary,
                                              width: 1,
                                            ),
                                          ),
                                          child: InkWell(
                                            onTap: () => _selectDate(date),
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                left: 10.0,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Text(
                                                    DateFormat(
                                                      'EEEE, MMM d, y',
                                                    ).format(date),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          _isDateSelected(date)
                                                              ? Colors.white
                                                              : AppColor
                                                                  .primary,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.delete,
                                                      color:
                                                          _isDateSelected(date)
                                                              ? Colors.white
                                                              : AppColor
                                                                  .primary,
                                                      size: 20,
                                                    ),
                                                    onPressed:
                                                        () =>
                                                            _deleteScheduledDate(
                                                              date,
                                                            ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: Column(
                    children: [
                      const SizedBox(height: 90),
                      InkWell(
                        onTap: () => _showTimePicker(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColor.primary,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child:
                            _selectedDate == null
                                ? const Center(
                                  child: Text(
                                    'Select a date to view time slots',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                )
                                : ListView.builder(
                                  padding: const EdgeInsets.all(8.0),
                                  itemCount:
                                      _timeSlots[DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(_selectedDate!)]
                                          ?.length ??
                                      0,
                                  itemBuilder: (context, index) {
                                    final time =
                                        _timeSlots[DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(_selectedDate!)]![index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColor.primary,
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                time.format(context),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                onPressed:
                                                    () => _deleteTimeSlot(time),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadScheduledDates() async {
    if (_selectedStaff == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('staff_schedules')
            .doc(_selectedStaff!.id)
            .collection('dates')
            .get();

    setState(() {
      _scheduledDates =
          snapshot.docs
              .map((doc) => (doc.data()['date'] as Timestamp).toDate())
              .where(
                (date) => date.isAfter(
                  DateTime.now().subtract(const Duration(days: 3)),
                ),
              )
              .toList()
            ..sort();
    });
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && _selectedStaff != null) {
      // Check if date already exists
      if (_scheduledDates.any(
        (date) =>
            date.year == picked.year &&
            date.month == picked.month &&
            date.day == picked.day,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This date is already scheduled')),
        );
        return;
      }

      // Add date to Firestore with date string as document ID
      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
      await FirebaseFirestore.instance
          .collection('staff_schedules')
          .doc(_selectedStaff!.id)
          .collection('dates')
          .doc(dateStr)
          .set({
            'date': Timestamp.fromDate(picked),
            'created_at': FieldValue.serverTimestamp(),
          });

      await _loadScheduledDates();
    }
  }

  Future<void> _deleteScheduledDate(DateTime date) async {
    if (_selectedStaff == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    await FirebaseFirestore.instance
        .collection('staff_schedules')
        .doc(_selectedStaff!.id)
        .collection('dates')
        .doc(dateStr)
        .delete();

    await _loadScheduledDates();
    
    // Clear time slots if the deleted date was selected
    if (_selectedDate != null &&
        _selectedDate!.year == date.year &&
        _selectedDate!.month == date.month &&
        _selectedDate!.day == date.day) {
      setState(() {
        _selectedDate = null;
        _timeSlots.clear();
      });
    }
  }

  bool _isDateSelected(DateTime date) {
    if (_selectedDate == null) return false;
    return date.year == _selectedDate!.year &&
        date.month == _selectedDate!.month &&
        date.day == _selectedDate!.day;
  }

  void _selectDate(DateTime date) {
    setState(() {
      if (_isDateSelected(date)) {
        _selectedDate = null;
        _timeSlots.clear();
      } else {
        _selectedDate = date;
        _loadTimeSlots();
      }
    });
  }

  Future<void> _showTimePicker() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date first')),
      );
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme(
                primary: AppColor.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
                secondary: AppColor.primary,
                onSecondary: Colors.white,
                brightness: Brightness.light,
                tertiary: AppColor.primary,
                onTertiary: Colors.white,
                error: AppColor.error,
                onError: Colors.white,
              ),
            ),
            child: child!,
          ),
      initialTime: TimeOfDay.now(),
    );

    if (picked != null && _selectedDate != null && _selectedStaff != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      // Add time to Firestore
      await FirebaseFirestore.instance
          .collection('staff_schedules')
          .doc(_selectedStaff!.id)
          .collection('dates')
          .doc(dateStr)
          .set({
            'date': Timestamp.fromDate(_selectedDate!),
            'times': FieldValue.arrayUnion([
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
            ]),
          }, SetOptions(merge: true));

      await _loadTimeSlots();
    }
  }

  Future<void> _loadTimeSlots() async {
    if (_selectedDate == null || _selectedStaff == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final doc =
        await FirebaseFirestore.instance
            .collection('staff_schedules')
            .doc(_selectedStaff!.id)
            .collection('dates')
            .doc(dateStr)
            .get();

    setState(() {
      if (doc.exists && doc.data()?['times'] != null) {
        final times = List<String>.from(doc.data()!['times']);
        _timeSlots[dateStr] =
            times.map((time) {
              final parts = time.split(':');
              return TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            }).toList();
      } else {
        _timeSlots[dateStr] = [];
      }
    });
  }

  Future<void> _deleteTimeSlot(TimeOfDay time) async {
    if (_selectedDate == null || _selectedStaff == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    await FirebaseFirestore.instance
        .collection('staff_schedules')
        .doc(_selectedStaff!.id)
        .collection('dates')
        .doc(dateStr)
        .update({
          'times': FieldValue.arrayRemove([timeStr]),
        });

    await _loadTimeSlots();
  }
}
