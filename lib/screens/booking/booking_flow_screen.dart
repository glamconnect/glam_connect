import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/service_model.dart';
import 'package:glam_connect/models/staff_model.dart';
import 'package:glam_connect/providers/booking_provider.dart';
import 'package:glam_connect/providers/main_provider.dart';
import 'package:glam_connect/utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/service_category_model.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  final ServiceModel service;
  final ServiceCategory category;

  const BookingFlowScreen({
    super.key,
    required this.service,
    required this.category,
  });

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  List<StaffModel> _staffList = [];
  StaffModel? _selectedStaff;
  List<DateTime> _scheduledDates = [];
  DateTime? _selectedDate;
  Map<String, List<TimeOfDay>> _timeSlots = {};
  TimeOfDay? _selectedTime;
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('staff')
              .where('salonId', isEqualTo: widget.service.salonId)
              .where('isActive', isEqualTo: true)
              .get();

      if (!mounted) return;

      setState(() {
        _staffList =
            snapshot.docs
                .map(
                  (doc) => StaffModel.fromJson({'id': doc.id, ...doc.data()}),
                )
                .toList();
        _isLoading = false;
      });

      if (_staffList.isNotEmpty) {
        // Load dates for the first staff member by default
        _selectedStaff = _staffList.first;
        _loadScheduledDates();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Error'),
                content: Text('Failed to load staff: $e'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );
      }
    }
  }

  Future<void> _loadScheduledDates() async {
    if (_selectedStaff == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('staff_schedules')
              .doc(_selectedStaff!.id)
              .collection('dates')
              .get();

      if (!mounted) return;

      setState(() {
        _scheduledDates =
            snapshot.docs
                .map((doc) => (doc.data()['date'] as Timestamp).toDate())
                .where(
                  (date) => date.isAfter(
                    DateTime.now().subtract(const Duration(days: 1)),
                  ),
                )
                .toList()
              ..sort();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Error'),
                content: Text('Failed to load dates: $e'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );
      }
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
        // Also test the structure directly
        _testTimeSlotStructure(date);
      }
    });
  }

  Future<void> _testTimeSlotStructure(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    print('\n==== TESTING TIME SLOT STRUCTURE ====');
    print('Date: $dateStr, Staff ID: ${_selectedStaff?.id}');

    try {
      // First check if the document exists
      final docRef = FirebaseFirestore.instance
          .collection('staff_schedules')
          .doc(_selectedStaff!.id)
          .collection('dates')
          .doc(dateStr);

      final doc = await docRef.get();
      print('Document exists: ${doc.exists}');

      if (doc.exists) {
        print('Document data: ${doc.data()}');

        // Check if times field exists and its type
        if (doc.data() != null && doc.data()!.containsKey('times')) {
          final times = doc.data()!['times'];
          print('Times field type: ${times.runtimeType}');
          print('Times content: $times');

          if (times is List) {
            print('Times is a list with ${times.length} items');
            if (times.isNotEmpty) {
              print('First time format: ${times.first}');
            }
          }
        } else {
          print('Document does not contain a "times" field');
        }
      }
    } catch (e) {
      print('Error testing time slot structure: $e');
    }
    print('==== END TEST ====\n');
  }

  Future<void> _loadTimeSlots() async {
    if (_selectedDate == null || _selectedStaff == null) return;

    setState(() => _isLoading = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      print('Loading time slots for date: $dateStr');

      final doc =
          await FirebaseFirestore.instance
              .collection('staff_schedules')
              .doc(_selectedStaff!.id)
              .collection('dates')
              .doc(dateStr)
              .get();

      if (!mounted) return;

      print(
        'Document exists: ${doc.exists}, has times: ${doc.data()?['times'] != null}',
      );
      if (doc.exists) {
        print('Document data: ${doc.data()}');
      }

      setState(() {
        // Check for various possible field names for time slots
        if (doc.exists) {
          List<String> times = [];
          
          // Check different possible field names
          if (doc.data()?['times'] != null) {
            times = List<String>.from(doc.data()!['times']);
            print('Times from Firestore (times field): $times');
          } else if (doc.data()?['timeSlots'] != null) {
            times = List<String>.from(doc.data()!['timeSlots']);
            print('Times from Firestore (timeSlots field): $times');
          } else if (doc.data()?['availableTimes'] != null) {
            times = List<String>.from(doc.data()!['availableTimes']);
            print('Times from Firestore (availableTimes field): $times');
          } else if (doc.data()?['slots'] != null) {
            times = List<String>.from(doc.data()!['slots']);
            print('Times from Firestore (slots field): $times');
          }
          
          if (times.isNotEmpty) {
            _timeSlots[dateStr] = times.map((time) {
              final parts = time.split(':');
              if (parts.length >= 2) {
                return TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );
              } else {
                // Handle malformed time strings
                print('Malformed time string: $time');
                return null;
              }
            })
            .where((time) => time != null) // Filter out null values
            .cast<TimeOfDay>() // Cast to non-nullable TimeOfDay
            .toList();
            print('Parsed time slots: ${_timeSlots[dateStr]?.length} slots');
          } else {
            _timeSlots[dateStr] = [];
            print('No time slots found in any field for date: $dateStr');
          }
        } else {
          _timeSlots[dateStr] = [];
          print('No document found for date: $dateStr');
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Error'),
                content: Text('Failed to load time slots: $e'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );
      }
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedStaff == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Incomplete Booking'),
              content: const Text(
                'Please select staff, date, and time to book an appointment.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
      return;
    }

    final currentUser = ref.read(mainProvider).currentUser;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final appointmentDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await ref
          .read(bookingProvider)
          .createBooking(
            serviceId: widget.service.id,
            salonId: widget.service.salonId,
            customerId: currentUser.id,
            staffId: _selectedStaff!.id,
            appointmentDate: appointmentDate,
            note: _noteController.text.trim(),
          );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Error'),
                content: Text('Failed to create booking: $e'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service.name),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Staff Dropdown
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
                                _selectedTime = null;
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

                  // Date and Time Selection
                  Expanded(
                    child: Row(
                      children: [
                        // Date List - Left Side
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child:
                                    _scheduledDates.isEmpty
                                        ? const Center(
                                          child: Text(
                                            'No available dates',
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
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _isDateSelected(date)
                                                            ? AppColor.primary
                                                            : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          50,
                                                        ),
                                                    border: Border.all(
                                                      color: AppColor.primary,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 12.0,
                                                          horizontal: 16.0,
                                                        ),
                                                    child: Text(
                                                      DateFormat(
                                                        'EEEE, MMM d, y',
                                                      ).format(date),
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            _isDateSelected(
                                                                  date,
                                                                )
                                                                ? Colors.white
                                                                : AppColor
                                                                    .primary,
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

                        // Time Slots - Right Side
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: Column(
                            children: [
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
                                                ).format(
                                                  _selectedDate!,
                                                )]![index];
                                            final isSelected =
                                                _selectedTime != null &&
                                                _selectedTime!.hour ==
                                                    time.hour &&
                                                _selectedTime!.minute ==
                                                    time.minute;

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8.0,
                                              ),
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedTime = time;
                                                  });
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isSelected
                                                            ? AppColor.primary
                                                            : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          50,
                                                        ),
                                                    border: Border.all(
                                                      color: AppColor.primary,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 10.0,
                                                          horizontal: 16.0,
                                                        ),
                                                    child: Text(
                                                      time.format(context),
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            isSelected
                                                                ? Colors.white
                                                                : AppColor
                                                                    .primary,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
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
                      ],
                    ),
                  ),

                  // Notes and Submit Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Notes Field
                        TextField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            labelText: 'Notes',
                            labelStyle: const TextStyle(color: Colors.grey),
                            hintText: 'Any special requests?',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColor.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          maxLines: 3,
                        ),

                        const SizedBox(height: 24),

                        // Submit Button
                        ElevatedButton(
                          onPressed:
                              _selectedStaff != null &&
                                      _selectedDate != null &&
                                      _selectedTime != null
                                  ? _submitBooking
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            disabledBackgroundColor: Colors.grey[300],
                          ),
                          child: const Text(
                            'Book Appointment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final String label;
  final bool isCompleted;
  final bool isActive;

  const _ProgressStep({
    required this.label,
    required this.isCompleted,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isCompleted || isActive ? AppColor.primary : Colors.grey[300],
          ),
          child:
              isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColor.primary : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ProviderSelectionStep extends ConsumerWidget {
  final ServiceModel service;
  final Function(StaffModel?) onSelectStaff;

  const _ProviderSelectionStep({
    required this.service,
    required this.onSelectStaff,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(salonStaffProvider(service.salonId));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Select the Provider',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          staffAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
            data:
                (staff) => Expanded(
                  child: ListView(
                    children: [
                      // Any Provider Option
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: const Icon(Icons.person_outline),
                        ),
                        title: const Text('Or select Any'),
                        onTap: () => onSelectStaff(null),
                      ),
                      const Divider(),
                      ...staff.map(
                        (staffMember) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                staffMember.photoUrl != null
                                    ? NetworkImage(staffMember.photoUrl!)
                                    : null,
                            child:
                                staffMember.photoUrl == null
                                    ? const Icon(Icons.person)
                                    : null,
                          ),
                          title: Text(staffMember.name),
                          onTap: () => onSelectStaff(staffMember),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentSelectionStep extends ConsumerWidget {
  final String staffId;
  final Function(DateTime, TimeOfDay) onSelectDateTime;

  const _AppointmentSelectionStep({
    required this.staffId,
    required this.onSelectDateTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityAsync = ref.watch(staffAvailabilityProvider(staffId));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Select the Appointment',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          availabilityAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (slots) {
              // Group slots by date
              final slotsByDate = <DateTime, List<DateTime>>{};
              for (final slot in slots) {
                final date = DateTime(slot.year, slot.month, slot.day);
                if (!slotsByDate.containsKey(date)) {
                  slotsByDate[date] = [];
                }
                slotsByDate[date]!.add(slot);
              }

              return Expanded(
                child: Row(
                  children: [
                    // Dates
                    Expanded(
                      child: ListView.builder(
                        itemCount: slotsByDate.length,
                        itemBuilder: (context, index) {
                          final date = slotsByDate.keys.elementAt(index);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: OutlinedButton(
                              onPressed: () {
                                final times = slotsByDate[date]!;
                                if (times.isNotEmpty) {
                                  onSelectDateTime(
                                    date,
                                    TimeOfDay(
                                      hour: times.first.hour,
                                      minute: times.first.minute,
                                    ),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColor.primary,
                                side: const BorderSide(color: AppColor.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                DateFormat('EEE dd-MM-yyyy').format(date),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Times
                    Expanded(
                      child: ListView.builder(
                        itemCount: slots.length,
                        itemBuilder: (context, index) {
                          final slot = slots[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: OutlinedButton(
                              onPressed: () {
                                onSelectDateTime(
                                  slot,
                                  TimeOfDay(
                                    hour: slot.hour,
                                    minute: slot.minute,
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColor.primary,
                                side: const BorderSide(color: AppColor.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(DateFormat('hh:mm a').format(slot)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ConfirmationStep extends StatelessWidget {
  final StaffModel staff;
  final DateTime date;
  final TimeOfDay time;
  final TextEditingController noteController;
  final VoidCallback onSubmit;

  const _ConfirmationStep({
    required this.staff,
    required this.date,
    required this.time,
    required this.noteController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Provider Info
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    staff.photoUrl != null
                        ? NetworkImage(staff.photoUrl!)
                        : null,
                child: staff.photoUrl == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 16),
              Text(
                staff.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Selected Date & Time
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    side: const BorderSide(color: AppColor.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(DateFormat('EEE dd-MM-yyyy').format(date)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    side: const BorderSide(color: AppColor.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Note
          const Text(
            'Note',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add a note for your appointment...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Submit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
