import 'package:flutter/material.dart';
import 'package:flutter_fe/model/tasker_scheduler.dart';
import 'package:flutter_fe/view/nav/user_navigation.dart';
import 'package:table_calendar/table_calendar.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    Map<DateTime, List<TimeSlot>> schedule =
        await _taskerSchedulerController.getTaskerSchedule();
    if (schedule != null) {
      _availabilitySlots.addAll(schedule.map((key, value) => MapEntry(
            key,
            value
                .map((slot) => TimeSlot(
                      startTime: slot.startTime,
                      endTime: slot.endTime,
                      isAvailable: slot.isAvailable,
                    ))
                .toList(),
          )));
      setState(() {}); // Update UI after loading data
    }
  }
  //Main Screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          //Main Calendar
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
              });
            },
            onRangeSelected: (start, end, focusedDay) {
              setState(() {
                _selectedFromDate = start;
                _selectedToDate = end;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            eventLoader: (day) {
              return _availabilitySlots[
                          DateTime(day.year, day.month, day.day)] ??
                  [];
            },
          ),
          Expanded(
            child: _selectedDay == null
                ? Center(child: Text('Select a day to set availability'))
                : _buildTimeSlots(),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_availabilitySlots.isNotEmpty) {
                String result = await _taskerSchedulerController
                    .setTaskerSchedule(_availabilitySlots);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result),
                      backgroundColor: Colors.green,
                    ),
                  );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("No availability slots selected"),
                      backgroundColor: Colors.red,
                    ),
                  );
              }
            },
            style: ButtonStyle( // Assuming ButtonStyle is correctly defined
              backgroundColor: WidgetStateProperty.all<Color>(Color(0XFF170A66)),
            ),
            child: Text(
              "Set Schedule",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 20)
        ],
      ),
      floatingActionButton: _selectedDay == null
          ? null
          : FloatingActionButton(
              onPressed: _addTimeSlot,
              child: Icon(Icons.add),
            ),
    );
  }

  Widget _buildTimeSlots() {
    final selectedDate = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );
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
          child: ListView.builder(
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: ListTile(
                  leading: Icon(Icons.access_time),
                  title: Text(
                      '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}'),
                  subtitle:
                      Text(slot.isAvailable ? 'Available' : 'Unavailable'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        icon: Icon(Icons.copy),
                        onSelected: (String value) {
                          if (value == 'weeks') {
                            _copySlotToNextWeeks(slot);
                          } else if (value == 'days') {
                            _copySlotToSpecificDay(slot);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'weeks',
                            child: Text('Copy to future weeks'),
                          ),
                          PopupMenuItem<String>(
                            value: 'days',
                            child: Text('Copy to specific day'),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteTimeSlot(selectedDate, index),
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

    final selectedDate = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );

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

      // Sort slots by start time
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
      builder: (BuildContext context) {
        return NumberPickerDialog(
          minValue: 1,
          maxValue: 12,
          title: Text('Copy to future weeks'),
          message: Text('How many weeks ahead?'),
        );
      },
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
            isAvailable: true,
          ),
        );
      }
    });
  }

  Future<void> _copySlotToSpecificDay(TimeSlot slot) async {
    // Use a simple date picker that returns a single date
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
          isAvailable: true,
        ),
      );

      // Sort slots by start time
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
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      default:
        return 'December';
    }
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
