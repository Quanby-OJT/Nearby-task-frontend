// calendar_availability_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_fe/view/nav/user_navigation.dart';
import 'package:table_calendar/table_calendar.dart';

class ScheduleManagement extends StatefulWidget {
  @override
  _ScheduleManagementState createState() => _ScheduleManagementState();
}

class _ScheduleManagementState extends State<ScheduleManagement> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<TimeSlot>> _availabilitySlots = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   automaticallyImplyLeading: false,
      //   title: Text(
      //     'Set Schedule',
      //     style:
      //         TextStyle(color: Color(0xFF0272B1), fontWeight: FontWeight.bold),
      //   ),
      //   backgroundColor: Colors.transparent,
      //   actions: [
      //     IconButton(
      //       icon: Icon(Icons.calendar_view_month),
      //       onPressed: () {
      //         setState(() {
      //           _calendarFormat = _calendarFormat == CalendarFormat.month
      //               ? CalendarFormat.week
      //               : CalendarFormat.month;
      //         });
      //       },
      //     ),
      //   ],
      // ),
      appBar: NavUserScreen(),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
        ],
      ),
      floatingActionButton: _selectedDay == null
          ? null
          : FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: _addTimeSlot,
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
            'Availability for ${_selectedDay!.toString().split(' ')[0]}',
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
                      IconButton(
                        icon: Icon(Icons.copy),
                        onPressed: () => _copySlotToNextWeeks(slot),
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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

  NumberPickerDialog({
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
