import 'package:flutter/material.dart';
import 'package:flutter_fe/model/timeSlot.dart';
import 'package:flutter_fe/service/tasker_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_fe/model/tasker_scheduler.dart';

class ScheduleManagement extends StatefulWidget {
  const ScheduleManagement({super.key});

  @override
  _ScheduleManagementState createState() => _ScheduleManagementState();
}

class _ScheduleManagementState extends State<ScheduleManagement> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TaskerService _taskerSchedulerController = TaskerService();
  final Map<DateTime, List<TimeSlot>> _availabilitySlots = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<DateTime, List<TimeSlot>> schedule =
          await _taskerSchedulerController.getTaskerSchedule();

      setState(() {
        _availabilitySlots.clear();
        _availabilitySlots.addAll(schedule);
        _isLoading = false;
        if (schedule.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("No schedules found"),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          _selectedDay ??= schedule.keys.first;
          _focusedDay = _selectedDay ?? DateTime.now();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading schedules: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Text(
              "Schedule Management",
              style: GoogleFonts.montserrat(
                color: Color(0xFF2A1999),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 5),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSchedule,
            tooltip: 'Refresh Schedules',
            color: Color(0xFF2A1999),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) =>
                    _selectedDay != null ? isSameDay(_selectedDay, day) : false,
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    debugPrint("Selected day: $selectedDay");
                  });
                },
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                eventLoader: (day) {
                  final dateKey = DateTime(day.year, day.month, day.day);
                  final slots = _availabilitySlots[dateKey] ?? [];
                  debugPrint("Event loader for $dateKey: $slots");
                  return slots;
                },
              ),
              Expanded(
                child: _selectedDay == null
                    ? Center(
                        child: _availabilitySlots.isEmpty
                            ? Text('No schedules available. Add one!')
                            : Text('Select a day to view or set availability'),
                      )
                    : _buildTimeSlots(),
              ),
              SizedBox(height: 20),
            ],
          ),
          if (_isLoading) Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRangeTimeSlots,
        tooltip: 'Add Time Slot Range',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildTimeSlots() {
    if (_selectedDay == null) {
      return Center(child: Text('No day selected'));
    }
    final selectedDate =
        DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final slots = _availabilitySlots[selectedDate] ?? [];

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Availability for ${getMonthName(_selectedDay!.month)} ${_selectedDay!.day}, ${_selectedDay!.year}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: slots.isEmpty
              ? Center(child: Text('No slots for this day. Add one!'))
              : ListView.builder(
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    return Card(
                      margin:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: ListTile(
                        leading: Icon(Icons.access_time),
                        title: Text(
                            '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}'),
                        subtitle: Text(
                            slot.isAvailable ? 'Available' : 'Unavailable'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteTimeSlot(selectedDate, index, slot.id),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _editTimeSlot(slot),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>?> _pickDateAndTimeSlot(String title) async {
    DateTime? selectedDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (pickedDate != null) {
                  selectedDate = pickedDate;
                }
              },
              child: Text(
                selectedDate == null
                    ? 'Select Date'
                    : '${getMonthName(selectedDate!.month)} ${selectedDate!.day}, ${selectedDate!.year}',
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: 9, minute: 0),
                );
                if (pickedTime != null) {
                  startTime = pickedTime;
                }
              },
              child: Text(
                startTime == null
                    ? 'Select Start Time'
                    : _formatTime(startTime!),
              ),
            ),
            TextButton(
              onPressed: () async {
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: 10, minute: 0),
                );
                if (pickedTime != null) {
                  endTime = pickedTime;
                }
              },
              child: Text(
                endTime == null ? 'Select End Time' : _formatTime(endTime!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (selectedDate == null ||
                  startTime == null ||
                  endTime == null) {
                _showSnackBar('Please fill all fields', Colors.red);
                return;
              }
              if (endTime!.hour * 60 + endTime!.minute <=
                  startTime!.hour * 60 + startTime!.minute) {
                _showSnackBar('End time must be after start time', Colors.red);
                return;
              }
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );

    if (selectedDate == null || startTime == null || endTime == null) {
      return null;
    }

    return {
      'date': selectedDate,
      'timeSlot': TimeSlot(
        id: 0,
        tasker_id: 0,
        startTime: startTime!,
        endTime: endTime!,
        isAvailable: true,
      ),
    };
  }

  Future<void> _addRangeTimeSlots() async {
    // First dialog: Start date and time slot
    final startResult =
        await _pickDateAndTimeSlot('Select Start Date and Time');
    if (startResult == null) return;

    DateTime startDate = startResult['date'];
    TimeSlot startSlot = startResult['timeSlot'];

    // Second dialog: End date and time slot
    final endResult = await _pickDateAndTimeSlot('Select End Date and Time');
    if (endResult == null) return;

    DateTime endDate = endResult['date'];
    TimeSlot endSlot = endResult['timeSlot'];

    // Validate date range
    if (endDate.isBefore(startDate)) {
      _showSnackBar('End date must be after start date', Colors.red);
      return;
    }

    // Generate daily slots for the range
    List<Map<String, dynamic>> serializedSlots = [];
    DateTime current = startDate;
    while (!current.isAfter(endDate)) {
      TimeSlot slot = current.isAtSameMomentAs(startDate)
          ? startSlot
          : current.isAtSameMomentAs(endDate)
              ? endSlot
              : startSlot; // Use startSlot for intermediate days

      if (!_hasOverlap(current, slot)) {
        serializedSlots.add(TaskerScheduler(
          id: 0,
          tasker_id: 0,
          dateScheduled:
              '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}',
          startTime: _formatTime(slot.startTime),
          endTime: _formatTime(slot.endTime),
          isAvailable: slot.isAvailable,
        ).toJson());
      }
      current = current.add(Duration(days: 1));
    }

    if (serializedSlots.isEmpty) {
      _showSnackBar('No valid slots to add due to overlaps', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    final result =
        await _taskerSchedulerController.setTaskerSchedule(serializedSlots);
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result),
        backgroundColor: result.contains("Error") ? Colors.red : Colors.green,
      ),
    );

    if (!result.contains('Error')) {
      current = startDate;
      while (!current.isAfter(endDate)) {
        TimeSlot slot = current.isAtSameMomentAs(startDate)
            ? startSlot
            : current.isAtSameMomentAs(endDate)
                ? endSlot
                : startSlot;
        if (!_hasOverlap(current, slot)) {
          setState(() {
            _availabilitySlots.putIfAbsent(current, () => []).add(slot);
            _sortTimeSlots(current);
          });
        }
        current = current.add(Duration(days: 1));
      }
      await _loadSchedule();
    }
  }

  Future<void> _editTimeSlot(TimeSlot slot) async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: slot.startTime,
    );

    if (startTime == null) return;

    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute),
    );

    if (endTime == null) return;

    if (endTime.hour * 60 + endTime.minute <=
        startTime.hour * 60 + startTime.minute) {
      _showSnackBar('End time must be after start time', Colors.red);
      return;
    }

    final selectedDate =
        DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

    TimeSlot updatedSlot = TimeSlot(
      id: slot.id,
      tasker_id: slot.tasker_id,
      startTime: startTime,
      endTime: endTime,
      isAvailable: slot.isAvailable,
    );

    setState(() => _isLoading = true);

    String formattedDate =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    Map<String, dynamic> serializedSlot = {
      "scheduled_date": formattedDate,
      "start_time": _formatTime(updatedSlot.startTime),
      "end_time": _formatTime(updatedSlot.endTime),
    };

    String result = await _taskerSchedulerController.editTaskerSchedule(
      slot.id,
      serializedSlot,
    );
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result),
        backgroundColor: result.contains("Error") ? Colors.red : Colors.green,
      ),
    );

    if (!result.contains("Error")) {
      setState(() {
        int slotIndex = _availabilitySlots[selectedDate]!.indexWhere(
          (s) => s.id == slot.id,
        );

        if (slotIndex != -1) {
          _availabilitySlots[selectedDate]![slotIndex] = updatedSlot;
          _sortTimeSlots(selectedDate);
        }
      });

      await _loadSchedule();
    }
  }

  void _deleteTimeSlot(DateTime date, int index, int id) async {
    debugPrint("Deleting slot at $date, index $index, id $id");

    String result = await _taskerSchedulerController.deleteTaskerSchedule(id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result),
        backgroundColor: result.contains("Error") ? Colors.red : Colors.green,
      ),
    );
    if (result.contains("Error")) return;

    setState(() {
      _availabilitySlots[date]!.removeAt(index);
      if (_availabilitySlots[date]!.isEmpty) {
        _availabilitySlots.remove(date);
      }
    });
  }

  void _sortTimeSlots(DateTime date) {
    _availabilitySlots[date]?.sort((a, b) =>
        (a.startTime.hour * 60 + a.startTime.minute)
            .compareTo(b.startTime.hour * 60 + b.startTime.minute));
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  bool _hasOverlap(DateTime date, TimeSlot newSlot) {
    final slots = _availabilitySlots[date] ?? [];
    final newStart = newSlot.startTime.hour * 60 + newSlot.startTime.minute;
    final newEnd = newSlot.endTime.hour * 60 + newSlot.endTime.minute;
    for (final slot in slots) {
      final start = slot.startTime.hour * 60 + slot.startTime.minute;
      final end = slot.endTime.hour * 60 + slot.endTime.minute;
      if (newStart < end && newEnd > start) return true;
    }
    return false;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
