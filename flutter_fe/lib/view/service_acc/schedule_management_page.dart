import 'package:flutter/material.dart';
import 'package:flutter_fe/model/timeSlot.dart';
import 'package:flutter_fe/service/tasker_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_fe/model/tasker_scheduler.dart';
import 'package:flutter_fe/controller/tasker_scheduler_controller.dart';

class ScheduleManagement extends StatefulWidget {
  const ScheduleManagement({super.key});

  @override
  _ScheduleManagementState createState() => _ScheduleManagementState();
}

class _ScheduleManagementState extends State<ScheduleManagement> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
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
              if (_selectedFromDate != null && _selectedToDate != null)
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Selected Range: ${getMonthName(_selectedFromDate!.month)} ${_selectedFromDate!.day}, ${_selectedFromDate!.year} - '
                        '${getMonthName(_selectedToDate!.month)} ${_selectedToDate!.day}, ${_selectedToDate!.year}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _selectedFromDate = null;
                          _selectedToDate = null;
                        }),
                        tooltip: 'Clear Range',
                      ),
                    ],
                  ),
                ),
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                rangeStartDay: _selectedFromDate,
                rangeEndDay: _selectedToDate,
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
                onRangeSelected: (start, end, focusedDay) {
                  setState(() {
                    _selectedFromDate = start;
                    _selectedToDate = end;
                    _focusedDay = focusedDay;
                    debugPrint("Range selected: $start to $end");
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
      floatingActionButton: _selectedDay == null
          ? null
          : FloatingActionButton(
              onPressed: _addTimeSlot,
              tooltip: 'Add Time Slot',
              child: Icon(Icons.add),
            ),
    );
  }

  Widget _buildTimeSlots() {
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

  Future<TimeSlot?> _pickTimeSlot({required TimeOfDay initialStart}) async {
    final startTime =
        await showTimePicker(context: context, initialTime: initialStart);
    if (startTime == null) return null;

    final endTime = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute),
    );
    if (endTime == null) return null;

    if (endTime.hour * 60 + endTime.minute <=
        startTime.hour * 60 + startTime.minute) {
      _showSnackBar('End time must be after start time', Colors.red);
      return null;
    }

    return TimeSlot(
      id: 0,
      tasker_id: 0,
      startTime: startTime,
      endTime: endTime,
      isAvailable: true,
    );
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

  Future<void> _addTimeSlot() async {
    final newSlot =
        await _pickTimeSlot(initialStart: const TimeOfDay(hour: 9, minute: 0));
    if (newSlot == null) return;

    final selectedDate =
        DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

    if (_hasOverlap(selectedDate, newSlot)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Time slot overlaps with an existing slot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final serializedSlot = TaskerScheduler(
      id: 0,
      tasker_id: 0,
      dateScheduled:
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
      startTime: _formatTime(newSlot.startTime),
      endTime: _formatTime(newSlot.endTime),
      isAvailable: newSlot.isAvailable,
    ).toJson();

    setState(() => _isLoading = true);
    final result =
        await _taskerSchedulerController.setTaskerSchedule([serializedSlot]);
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result),
        backgroundColor: result.contains("Error") ? Colors.red : Colors.green,
      ),
    );

    if (!result.contains('Error')) {
      setState(() {
        _availabilitySlots.putIfAbsent(selectedDate, () => []).add(newSlot);
        _sortTimeSlots(selectedDate);
      });
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("End time must be after start time"),
          backgroundColor: Colors.red,
        ),
      );
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

          _availabilitySlots[selectedDate]!.sort((a, b) {
            final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
            final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
            return aMinutes.compareTo(bMinutes);
          });
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

class NumberPickerDialog extends StatefulWidget {
  final int minValue;
  final int maxValue;
  final Widget title;
  final Widget message;

  const NumberPickerDialog({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.title,
    required this.message,
  });

  @override
  _NumberPickerDialogState createState() => _NumberPickerDialogState();
}

class _NumberPickerDialogState extends State<NumberPickerDialog> {
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.minValue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.message,
          SizedBox(height: 16),
          DropdownButton<int>(
            value: _selectedValue,
            items: List.generate(
              widget.maxValue - widget.minValue + 1,
              (index) => DropdownMenuItem(
                value: widget.minValue + index,
                child: Text('${widget.minValue + index} weeks'),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _selectedValue = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedValue),
          child: Text('OK'),
        ),
      ],
    );
  }
}
