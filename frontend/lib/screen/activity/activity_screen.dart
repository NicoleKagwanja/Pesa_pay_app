// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<String>> _events = {
    DateTime(2025, 4, 5): ["Off Week"],
    DateTime(2025, 4, 18): ["Public Holiday - Easter"],
    DateTime(2025, 4, 12): ["Funeral"],
    DateTime(2025, 4, 20): ["Official Trip"],
  };

  List<String> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Activity Calendar")),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: _getEventsForDay(_selectedDay ?? _focusedDay)
                  .map(
                    (event) => ListTile(
                      leading: Icon(Icons.event, color: Colors.blue),
                      title: Text(event),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
