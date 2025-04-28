import 'package:flutter/material.dart';
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
  final TaskerSchedulerController _taskerSchedulerController =
      TaskerSchedulerController();
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
          // Set _selectedDay to a day with schedules for immediate display
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
        title: Text("Schedule Management"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSchedule,
            tooltip: 'Refresh Schedules',
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_availabilitySlots.isNotEmpty) {
                      setState(() => _isLoading = true);
                      final List<Map<String, dynamic>> serializedSlots = [];
                      _availabilitySlots.forEach((date, slots) {
                        for (var slot in slots) {
                          serializedSlots.add(TaskerScheduler(
                            dateScheduled:
                                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                            startTime: _formatTime(slot.startTime),
                            endTime: _formatTime(slot.endTime),
                            isAvailable: slot.isAvailable,
                          ).toJson());
                        }
                      });

                      String result = await _taskerSchedulerController
                          .setTaskerSchedule(serializedSlots);
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result),
                          backgroundColor: result.contains("Error")
                              ? Colors.red
                              : Colors.green,
                        ),
                      );
                      await _loadSchedule();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("No availability slots selected"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all<Color>(Color(0xFF170A66)),
                  ),
                  child: Text(
                    "Set Schedule",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
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
              child: Icon(Icons.add),
              tooltip: 'Add Time Slot',
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
                            PopupMenuButton<String>(
                              icon: Icon(Icons.copy),
                              onSelected: (value) {
                                if (value == 'weeks') {
                                  _copySlotToNextWeeks(slot);
                                } else if (value == 'days') {
                                  _copySlotToSpecificDay(slot);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                    value: 'weeks',
                                    child: Text('Copy to future weeks')),
                                PopupMenuItem(
                                    value: 'days',
                                    child: Text('Copy to specific day')),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteTimeSlot(selectedDate, index),
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

  Future<void> _addTimeSlot() async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
    );

    if (startTime == null) return;

    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute),
    );

    if (endTime == null) return;

    // Validate endTime > startTime
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

    setState(() {
      if (!_availabilitySlots.containsKey(selectedDate)) {
        _availabilitySlots[selectedDate] = [];
      }

      _availabilitySlots[selectedDate]!.add(
        TimeSlot(
          startTime: startTime,
          endTime: endTime,
          isAvailable: true,
        ),
      );

      _availabilitySlots[selectedDate]!.sort((a, b) {
        final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
        final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
        return aMinutes.compareTo(bMinutes);
      });
    });
  }

  void _deleteTimeSlot(DateTime date, int index) {
    setState(() {
      _availabilitySlots[date]!.removeAt(index);
      if (_availabilitySlots[date]!.isEmpty) {
        _availabilitySlots.remove(date);
      }
    });
  }

  Future<void> _copySlotToNextWeeks(TimeSlot slot) async {
    final int? weeks = await showDialog<int>(
      context: context,
      builder: (context) => NumberPickerDialog(
        minValue: 1,
        maxValue: 12,
        title: Text('Copy to future weeks'),
        message: Text('How many weeks ahead?'),
      ),
    );

    if (weeks == null) return;

    setState(() {
      for (int i = 1; i <= weeks; i++) {
        final futureDate = _selectedDay!.add(Duration(days: 7 * i));
        final dateKey =
            DateTime(futureDate.year, futureDate.month, futureDate.day);

        if (!_availabilitySlots.containsKey(dateKey)) {
          _availabilitySlots[dateKey] = [];
        }

        _availabilitySlots[dateKey]!.add(
          TimeSlot(
            startTime: slot.startTime,
            endTime: slot.endTime,
            isAvailable: slot.isAvailable,
          ),
        );

        _availabilitySlots[dateKey]!.sort((a, b) {
          final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
          final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
          return aMinutes.compareTo(bMinutes);
        });
      }
    });
  }

  Future<void> _copySlotToSpecificDay(TimeSlot slot) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDay!.add(Duration(days: 1)),
      firstDate: _selectedDay!.add(Duration(days: 1)),
      lastDate: _selectedDay!.add(Duration(days: 365)),
    );

    if (pickedDate == null) return;

    setState(() {
      final dateKey =
          DateTime(pickedDate.year, pickedDate.month, pickedDate.day);

      if (!_availabilitySlots.containsKey(dateKey)) {
        _availabilitySlots[dateKey] = [];
      }

      _availabilitySlots[dateKey]!.add(
        TimeSlot(
          startTime: slot.startTime,
          endTime: slot.endTime,
          isAvailable: slot.isAvailable,
        ),
      );

      _availabilitySlots[dateKey]!.sort((a, b) {
        final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
        final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
        return aMinutes.compareTo(bMinutes);
      });
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

class TimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAvailable;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
  });

  @override
  String toString() {
    return 'TimeSlot(start: ${_formatTime(startTime)}, end: ${_formatTime(endTime)}, available: $isAvailable)';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
